function rotateRectMatrix(matrix)
    matrow=size(matrix,1)
    matcol=size(matrix,2)
    rotmatrix=similar(matrix,Any,matcol,matrow)
    for row in 1:matrow
        for column in 1:matcol
            rotmatrix[column,row]=matrix[row,column]
        end
    end
    return rotmatrix
end
function denseheatmapSS(speciesToPlot,conditions,columns,rows,colorArray=palette(:Greys))
    colorArray=colorArray
    for species in speciesToPlot
        conditionIndex=1
        peakArray=[]
        meanArray=[]
        aucArray=[]
        steadystateArray=[]
        for condition in conditions
            lengthOfTC=size(DataFrame(CSV.File(folder*"/sol_"*condition*"_cell_1.csv")),2)-1
            conditionArray=zeros(last_cell,lengthOfTC)
            lineColor=colorArray[conditionIndex]
            virtExpFlag=false
            for i in first_cell:last_cell
                thisCellData=DataFrame(CSV.File(folder*"/sol_"*condition*"_cell_"*string(i)*".csv"))
                if !("names" in names(thisCellData))
                    insertcols!(thisCellData, 1, :names=>syms)
                end
                allNoneFloats=findall(eltype.(eachcol(thisCellData)).!=Float64)
                if length(allNoneFloats)>1
                    for index in allNoneFloats[2:end]
                        thisCellData[!,index]=parse.(Float64,thisCellData[:,index])
                    end
                end
                thisTC=zeros(1,size(thisCellData,2)-1)
                if endswith(species,"*")
                    virtExpFlag=true
                    speciesShort=species[1:end-1]
                    speciesIDs=intersect(findall( x ->occursin(speciesShort,x),syms),findall(x->!startswith(x,"t"),syms))
                    speciesNames=String.(syms[speciesIDs])
                    for thisName in speciesNames
                        thisSpeciesTC=Matrix(thisCellData[thisCellData[!,:names].==thisName,:])[2:end]

                        thisTC=thisTC.+thisSpeciesTC'
                    end
                else
                    thisTC=Matrix(thisCellData[thisCellData[!,:names].==species,:])[2:end]

                end
                conditionArray[i,:]=thisTC[1:lengthOfTC]
            end
            df = DataFrame(Float64.(conditionArray),:auto)
            meanOfCondition=mean(conditionArray, dims=1)
            max = maximum(meanOfCondition)
            auc = sum(meanOfCondition)/60
            meen=mean(meanOfCondition)
            SS=meanOfCondition[1]
                
            push!(steadystateArray,SS)
        end
        colo=colorArray
        preparray2=reshape(steadystateArray,(columns,rows))
        preparray2=rotateRectMatrix(preparray2)
        title2=string("SS ",species)
        steadystatemap=heatmap(preparray2, c=colo,
        xlabel="basal NIK", ylabel="basal IKK",
        title=title2)
        display(steadystatemap)
    end
end
function denseheatmapSS2(speciesToPlot,conditions,columns,rows,colorArray=palette(:Greys))
    for species in speciesToPlot
        conditionIndex=1
        peakArray=[]
        meanArray=[]
        aucArray=[]
        steadystateArray=[]
        for condition in conditions
            lengthOfTC=size(DataFrame(CSV.File(folder*"/sol_SS_"*condition*"_cell_1.csv")),2)-1
            conditionArray=zeros(last_cell,lengthOfTC)
            lineColor=colorArray[conditionIndex]
            virtExpFlag=false
            for i in first_cell:last_cell
                thisCellData=DataFrame(CSV.File(folder*"/sol_SS_"*condition*"_cell_"*string(i)*".csv"))
                if !("names" in names(thisCellData))
                    insertcols!(thisCellData, 1, :names=>syms)
                end
                allNoneFloats=findall(eltype.(eachcol(thisCellData)).!=Float64)
                if length(allNoneFloats)>1
                    for index in allNoneFloats[2:end]
                        thisCellData[!,index]=parse.(Float64,thisCellData[:,index])
                    end
                end
                thisTC=zeros(1,size(thisCellData,2)-1)
                if endswith(species,"*")
                    virtExpFlag=true
                    speciesShort=species[1:end-1]
                    speciesIDs=intersect(findall( x ->occursin(speciesShort,x),syms),findall(x->!startswith(x,"t"),syms))
                    speciesNames=String.(syms[speciesIDs])
                    for thisName in speciesNames
                        thisSpeciesTC=Matrix(thisCellData[thisCellData[!,:names].==thisName,:])[2:end]

                        thisTC=thisTC.+thisSpeciesTC'
                    end
                else
                    thisTC=Matrix(thisCellData[thisCellData[!,:names].==species,:])[2:end]

                end
                conditionArray[i,:]=thisTC[1:lengthOfTC]
            end
            df = DataFrame(Float64.(conditionArray),:auto)
            meanOfCondition=mean(conditionArray, dims=1)

            SS=meanOfCondition[end]
                
            push!(steadystateArray,SS)
        end
        colo=colorArray
        preparray2=reshape(steadystateArray,(columns,rows))
        preparray2=rotateRectMatrix(preparray2)
        title2=string("SS ",species)
        steadystatemap=heatmap(preparray2, c=colo,
        xlabel="basal NIK", ylabel="basal IKK",
        title=title2)
        display(steadystatemap)
    end
end