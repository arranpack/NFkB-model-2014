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
function denseIKKNIKheatmap(speciesToPlot,conditions,columns,rows,colorArray=palette(:YlGn))
    for species in speciesToPlot
        conditionIndex=1
        peakArray=[]
        meanArray=[]
        aucArray=[]
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

            push!(peakArray,max)
            push!(meanArray,meen)
            push!(aucArray,auc)

            delta = 0.000025
            total_area = 0.0
            for i in range(1,length(conditionArray)-1,step=1)
                h1 = conditionArray[i]
                h2 = conditionArray[i+1]
                area = delta *( h1 + h2 )
                total_area += area
            end

        end
        colo=colorArray
        preparray1=reshape(peakArray,(columns,rows))
        preparray1=rotateRectMatrix(preparray1)
        title1=string("peak ",species)
        peakmap=heatmap(preparray1, c=colo,
        xlabel="basal NIK", ylabel="basal IKK",
        title=title1)
        display(peakmap)

#         preparray2=reshape(meanArray,(columns,rows))
#         preparray2=rotateRectMatrix(preparray2)
#         title2=string("mean ",species)
#         meanmap=heatmap(preparray2, c=colo,
#         xlabel="basal NIK", ylabel="basal IKK",
#         title=title2)
#         display(meanmap)

        preparray3=reshape(aucArray,(columns,rows))
        preparray3=rotateRectMatrix(preparray3)
        title3=string("auc ",species)
        aucmap=heatmap(preparray3,c=colo,
        xlabel="basal NIK", ylabel="basal IKK",
        title=title3)
        display(aucmap)
    end
end