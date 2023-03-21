#this is an old version please don't copy, find the runsimulations.jl from somewhere recent
function runSimulationNFkB(first_cell, last_cell, conditions,folder,IKKSSArray,IKKTCArray,NIKSSArray,NIKTCArray)
    starttime=Dates.format(now(),"HH:MM:SS")
    start=Dates.DateTime(now())
    println("started job at: ",starttime[1:5])
    mkpath(folder)
    #now lets loop through and solve the cell
    TCLength=1000*60
    maximumAttemptsAtSS=10
    include("variableNames.jl")
    include("scanIncludes.jl")
    originalParams=copy(paramVals)
    ikkIndex=findfirst(x -> x=="ikk1_ikkactivity", parameterNameList)
    NIKIndex=findfirst(x -> x=="nik_deg_mod", parameterNameList)
    
    thisDist=TruncatedNormal(1.0, preCV,0,Inf)


    Random.seed!(123)    


    allParams=[]
    allParams=Array{Any}(undef, size(parametersDF,1), last_cell)
    for cellIndex in first_cell:last_cell
        thisCellsParamVals=copy(originalParams)            

        for j in 1:size(parametersDF,1)
            if parametersDF[j,3]==1
                x = rand(thisDist, 1)
               thisCellsParamVals[j]=thisCellsParamVals[j].*x[1]
            end
        end
        #println(thisCellsParamVals)
        allParams[:,cellIndex]=thisCellsParamVals
    end
    df = DataFrame(allParams,:auto)
    #add the variable names and save to a file
    insertcols!(df, 1, :names=>parameterNameList)
    CSV.write(folder*"/allParams_runSimulationNew.csv",df);
    #println(size(allParams))
    #println(allParams[1])
    allParamsOriginal=copy(allParams)
    for condIndex in 1:length(conditions)
        allParams=copy(allParamsOriginal)
        thisCondition = conditions[condIndex]
        #TODO: consider making a condition scaling factor array here and just multiplying all prameters by it every time.
        
        print("Start condition "*thisCondition,":")
        odeName="odeModel"
        myFun=getfield(Main,Symbol(odeName))

        #define the function and the initial conditions
        f=ODEFunction(myFun,syms=Symbol.(syms))
        y0=zeros(length(syms))
    
        paramsListInThisCondition=paramsToChange[condIndex]
        modifyListInThisCondition=modifyAmount[condIndex]

        for thisParamIndex in 1:length(paramsListInThisCondition)
            thisParam=paramsListInThisCondition[thisParamIndex]
            thisParamsIndexInParamList=findfirst(x->x==thisParam,parameterNameList)
            allParams[thisParamsIndexInParamList,:]=allParams[thisParamsIndexInParamList,:].*modifyListInThisCondition[thisParamIndex]
        end  
        df = DataFrame(allParams,:auto)
        #add the variable names and save to a file
        insertcols!(df, 1, :names=>parameterNameList)
        CSV.write(folder*"/allParams_runSimulationNew_"*thisCondition*".csv",df);

        for i in first_cell:last_cell
            #figure out the name of this cell's ode file
            
            #DISTRIBUTE PARAMS
            
            print("cell "*string(i))
            thisCellsParamVals=copy(allParams[:,i])
            thisCellsParamVals[ikkIndex]=IKKSSArray[condIndex]
            thisCellsParamVals[NIKIndex]=NIKSSArray[condIndex]
            
      
    #     #now write this condition's CSV file to a folder of cells
    #     CSV.write(generatedCSVLocation*"/parameters_"*string(conditions[condIndex])*".csv", thisCondParamFile)

            prob=ODEProblem(f,y0,(0.0,maxTimeSS),thisCellsParamVals)

            solss=solve(prob,saveat=100.0,progress = true)
            print("SS ")

            #dynamic phase, use SS solution as initial conditions
            y0=vec(convert(Array, solss[:,end]))
            y0[y0.<0].=0
            
            #CSV.write(generatedCSVLocation*"/parameters_"*string(conditions[condIndex])*"_cell_"*string(i)*".csv", DataFrame(thisCellsParamVals,:auto))
            try
                thisCellsParamVals[ikkIndex]=IKKTCArray[condIndex]
                thisCellsParamVals[NIKIndex]=NIKTCArray[condIndex]
                
                f=ODEFunction(myFun,syms=syms)
                prob=ODEProblem(f,y0,(0.0,maxTimeTC),thisCellsParamVals)
                print("TC ")
                sol=solve(prob, abstol=1e-5,reltol=1e-3, saveat=1.0)
                #save("outputs/sol_"*thisCondition*"_cell_"*string(i)*".jld2", "solution", sol)
                df = DataFrame(Float64.(sol),:auto)
                #add the variable names and save to a file
                insertcols!(df, 1, :names=>syms)
                #CSV.write("outputs/sol_"*thisCondition*"_cell_"*string(i)*".csv",Tables.columntable(df));
                CSV.write(folder*"/sol_"*thisCondition*"_cell_"*string(i)*".csv",df);
            catch e
                println("error:")
                println(e)
            end

        end
        print("done "*thisCondition,"\n")

    end
    println("started: ",starttime)
    println("ended: ",Dates.format(now(),"HH:MM:SS"))
    e=Dates.DateTime(now())
    println(Dates.canonicalize(Dates.CompoundPeriod(e-start)))
end