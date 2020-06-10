nParaProcess=8 --parallel processes
phi1,phi2,phiStep=0,90,10
theta1,theta2,thetaStep=0,90,10
-- f1,f2,fStep=0.3e9,2e9,0.425e9 --1.490e9,2e9,0.17e9
f0List={470000000,640000000.000000,810000000,980000000,1320000000.00000,1490000000.00000,1660000000.00000,1830000000.00000}
-- f1,f2,fStep=0.4e9,0.4e9,0.425e9 --1.490e9,2e9,0.17e9
PAList={0,90}--PolarisationAngle,0 for VV, 90 for HH 
fekoDir=[[E:\ZM\0Work\3simuModel\20200523GaussModel\]]
stepDir = [[E:\ZM\0Work\3simuModel\20200416simlationModel\]]
stepName=[[1pWedge(1000_100_500)]]
-- stepName=[[test]]
gaussFormulaTxt=[[E:\ZM\0Work\1SimulationReport\CurveCalculation\GaussianStructure\GaussCurve(40)20200601.txt]]
gaussStartIndex,countStart=1,1
-----------------------------------------------------------------------------------------------------------------------
if f0List==nil then
    index,f0List=0,{}
    for f0Cache=f1,f2,fStep do index=index+1 f0List[index]=f0Cache end
end
f0Last=-1
samplesN=(phi2-phi1)/phiStep*(theta2-theta1)/thetaStep
countStartFlag=false
formulaTxtName=gaussFormulaTxt:sub(-gaussFormulaTxt:reverse():find([[\]])+1,-gaussFormulaTxt:reverse():find([[%.]])-1)
outFekoDir=fekoDir..formulaTxtName.."\\"
mkdirStr1="md "..outFekoDir
os.execute(mkdirStr1)
logFileName=[[lua.log]]
logLongName=outFekoDir..logFileName
count,nLoops,gaussIndex=0,#PAList*#f0List,0
logFileHd=io.open(logLongName,"w")
stringNote={}
--abbr:
--pprty property
--prj   project
--PlaneWave     PW
--frequency     frq
 if(1) then --initialize feko and create model	
    -- Set base import parameters
    importPprty = {}
    importPprty.AutoMergeWires = false
    importPprty.AutoStitchFaces = false
    importPprty.ExtrudeEnabled = true
    importPprty.HealingType = cf.Enums.ImportHealingTypeEnum.Standard
    importPprty.ImportScaleFactor = 1000
    importPprty.ImportViasEnabled = true
    importPprty.SimplifyModelEnabled = true
    importPprty.StitchTrimmedFacesEnabled = true
    importPprty.UseInfinitelyThinLayersEnabled = true
    importPprty.UseTwoStepImportEnabled = false
    -- Set base parameters for PlaneWaveSource
    PwPprty = cf.PlaneWave.GetDefaultProperties()
    PwPprty.DefinitionMethod = cf.Enums.PlaneWaveDefinitionMethodEnum.Multiple
    PwPprty.Label = "PlaneWaveSource1"
    PwPprty.StartPhi= phi1
    PwPprty.StartTheta= theta1
    PwPprty.EndPhi = phi2
    PwPprty.EndTheta = theta2
    PwPprty.PhiIncrement = phiStep
    PwPprty.ThetaIncrement = thetaStep
    --  Set base Farfield request parameters
    farfieldPprty = cf.FarField.GetDefaultProperties()
    farfieldPprty.CalculationDirection = cf.Enums.FarFieldCalculationDirectionEnum.FromPlaneWave
    farfieldPprty.Label = "FarField1"
    farfieldPprty.Advanced.ExportSettings.ASCIIEnabled = true --export *.ffe
end
lineX=io.lines(gaussFormulaTxt)
line1=lineX()
timeScript0=os.time()
while(line1) do
    time0=os.time()
    gaussIndex=gaussIndex+1
    if gaussIndex>=gaussStartIndex then
        count=0
        for indexF0,f0 in ipairs(f0List) do
            for indexPA,PA in ipairs(PAList) do
                count=count+1	
                time1=os.time()	
		if not countStartFlag then
                    if count==countStart then countStartFlag=true end
		end
                if countStartFlag then -- If it is or after (gaussIndex==gaussStartIndex,count==countStart)
                    fileName = stepName..line1..string.format("(Fre%gM_phi%dto%ddphi%d_theta%dto%ddtheta%d_Pol%d)",f0/(1e6),phi1,phi2,phiStep,theta1,theta2,thetaStep,PA)
                    if count==1 or (gaussIndex==gaussStartIndex and count==countStart) then -- If it's the first f0-PA Sample Point for current model or It's the first run from countStart
                   	 -- New project
                   	 app = cf.GetApplication()
                   	 prj = app:NewProject()	
                         -- Save project as
                         app:SaveAs(outFekoDir..fileName)
                   	 -- Modified solution entity: Model unit
                   	 prjPprty = prj:GetProperties()
                   	 prjPprty.ModelAttributes.Unit = cf.Enums.ModelUnitEnum.Millimetres
                   	 prj:SetProperties(prjPprty)	
                   	 -- Scale factor changed from 1 to 0.001
                   	 prj.ModelAttributes.ExtentsExponent = 5	
                   	 if(1) then-- Import And Create Gaussian head and union
                   	 GeometryImporter = prj.Importer.Geometry
                   	 GeometryImporter:SetProperties(importPprty)
                   	 importBodies=GeometryImporter:Import(stepDir..stepName..[[.STEP]])
                         -- Get Gauss Parameters from formula txt
                         line1Name=line1:gsub('-','N')
                         line1Name=line1Name:gsub("%.","p")
                         line1Name=line1Name:gsub("[(,)]","_")
                         line2=lineX()
                         line3=lineX()
                         line4=lineX()
                         L=line1:sub(line1:find('L')+1,line1:find('H')-1)
                         H=line1:sub(line1:find('H')+1,line1:find('A1')-1)
                         A1=line1:sub(line1:find('A1')+2,line1:find('A2')-1)
                         A2=line1:sub(line1:find('A2')+2,-2)
                   	 -- Created GaussianCurve
                   	 curvePprty = cf.AnalyticalCurve.GetDefaultProperties()
                   	 curvePprty.CartesianDescription.U = line2
                   	 curvePprty.CartesianDescription.V = line3
                   	 curvePprty.CartesianDescription.N = line4
                   	 curvePprty.Label = "GaussianCurve"..line1Name
                   	 curvePprty.ParametricStart = "0"
                   	 curvePprty.ParametricEnd = L
                   	 AnalyticalCurve1 = prj.Geometry:AddAnalyticalCurve(curvePprty)
                   	 -- Translate transform GaussianCurve
                   	 transPprty = cf.Translate.GetDefaultProperties()
                   	 transPprty.From.U = "0"
                   	 transPprty.From.V = "0"
                   	 transPprty.From.N = "0"
                   	 transPprty.To.U = "0"
                   	 transPprty.To.V = "0"
                   	 transPprty.To.N = "250"
                   	 Translate2 = AnalyticalCurve1.Transforms:AddTranslate(transPprty)
                   	 -- Copy and mirror transform GaussianCurve
                   	 mirrorPprty = cf.Mirror.GetDefaultProperties()
                   	 mirrorPprty.Origin.N = "0"
                   	 mirrorPprty.Origin.U = "0"
                   	 mirrorPprty.Origin.V = "0"
                   	 mirrorPprty.Plane = cf.Enums.MirrorPlaneEnum.UV --UV UN VN
                   	 mirrorPprty.RotationU = "0"
                   	 mirrorPprty.RotationV = "0"
                   	 newCurve=AnalyticalCurve1:CopyAndMirror(mirrorPprty)
                   	 -- Loft GaussianCurve to one Face
                   	 loftPprty = cf.Loft.GetDefaultProperties()
                   	 loftPprty.Label = "gaussFace"
                   	 gaussFace=prj.Geometry:Loft(newCurve,AnalyticalCurve1,loftPprty)
                   	 -- Sweep Gauss Face to a body
                   	 sweepPprty = cf.Sweep.GetDefaultProperties()
                   	 sweepPprty.To.V = "1000"
                   	 gaussHead=prj.Geometry:Sweep(gaussFace, sweepPprty)
                   	 -- Union import bodys and GaussBody
                   	 targets=importBodies
                   	 table.insert(targets,gaussHead)
                   	 unionBody=prj.Geometry:Union(targets)
                   	 View3D = app.Views["3D view 1"]
                   	 View3D:SetViewDirection(cf.Enums.ViewDirectionEnum.Isometric)
                   	 View3D:ZoomToExtents()
                   	 end -- Import And Create Gaussian head End
                   	 for i = 1,#unionBody.Faces do --Set CombinedField IntegralEquation
                   	     FaceA = unionBody.Faces[i]
                   	     faceProperties = FaceA:GetProperties()
                   	     faceProperties.IntegralEquation = cf.Enums.IntegralEquationTypeEnum.CombinedField
                   	     FaceA:SetProperties(faceProperties)
                   	 end
                   	 -- Set PlaneWaveSource
                         PwPprty.PolarisationAngle = PA
                         PlaneWaveSource1 = prj.SolutionConfigurations["StandardConfiguration1"].Sources:AddPlaneWave(PwPprty)
                   	 -- PlaneWaveSource1:SetProperties(PwPprty)
                   	 FarField1 = prj.SolutionConfigurations["StandardConfiguration1"].FarFields:Add(farfieldPprty)
                   	 -- Paralel ProcessCount 
                   	 CompLaunchOpt = prj.Launcher.Settings
                   	 launchPprty = CompLaunchOpt:GetProperties()
                   	 launchPprty.FEKO.Parallel.NumberOfProcessesEnabled = true
                   	 launchPprty.FEKO.Parallel.ProcessCount = nParaProcess
                   	 CompLaunchOpt:SetProperties(launchPprty)  
                    else -- If it's not the first f0-PA Sample Point for current model
                         -- Save project as
                         app:SaveAs(outFekoDir..fileName)                	
                         -- Set PlaneWaveSource   
                         PwPprty.PolarisationAngle = PA
                         PlaneWaveSource1:SetProperties(PwPprty)
                    end -- The first f0-PA Sample Point Part End
                    if f0~=f0Last then -- If the frequency is changed
                        -- Solution settings
                        SolverSettings_1 = prj.SolutionSettings.SolverSettings
                        solutionProperties = SolverSettings_1:GetProperties()
                        solutionProperties.MLFMMACASettings.ModelSolutionSolveType = cf.Enums.ModelSolutionSolveTypeEnum.MLFMM
                        -- solutionProperties.MLFMMACASettings.ModelSolutionSolveType = cf.Enums.ModelSolutionSolveTypeEnum.None
                        SolverSettings_1:SetProperties(solutionProperties)
                        -- Set the frequency to single frequency.
                        StandardConfiguration1 = prj.SolutionConfigurations["StandardConfiguration1"]
                        FrequencyRange1 = StandardConfiguration1.Frequency
                        frqPprty = FrequencyRange1:GetProperties()
                        frqPprty.Start = f0
                        FrequencyRange1:SetProperties(frqPprty) 
                        -- Mesh the model
                        MeshSettings = prj.Mesher.Settings
                        MeshSettings.MeshSizeOption=cf.Enums.MeshSizeOptionEnum.Standard	
                        proMesh=prj.Mesher:Mesh() 
                    end
                    geo=prj.Geometry[1]
                    triangleCount = geo.SimulationMeshInfo.TriangleCount                    
                    indexNote=1
                    stringNote[indexNote]=count.." of "..nLoops..string.format(" GaussIndex=%d ",gaussIndex)..fileName..".cfx :"
                    print(stringNote[indexNote])
                    indexNote=indexNote+1
                    stringNote[indexNote]="\tTriangles: "..triangleCount
                    print(stringNote[indexNote])
                    -- RunFEKO
                    errTimes,skipFlag=0,0
                    repeat
			app:Save()
			result=prj.Launcher:RunFEKO()
			if(result.Succeeded==false) then
			    errTimes=errTimes+1
			    ErrStr=result.Errors
                            indexNote=indexNote+1
                            stringNote[indexNote]="\t"..ErrStr
			    print(stringNote[indexNote])
			    errID=string.sub(ErrStr,string.find(ErrStr,"ERROR   %d*"))
			    if(errID=="ERROR   32945") then        
			        solutionProperties.MLFMMACASettings.ModelSolutionSolveType = cf.Enums.ModelSolutionSolveTypeEnum.None
			        SolverSettings_1:SetProperties(solutionProperties)
                                indexNote=indexNote+1
                                stringNote[indexNote]="\tSolution Changed: MLFMM to None"
			        print(stringNote[indexNote])
			    else
			        resultStr="\tSkipped. "
			        skipFlag=1
			    end  
			end
                    until(result.Succeeded==true or errTimes>1)
                    app:Save()
                    f0Last=f0
                    time2=os.time()
                    dtime12_sec=(time2-time1)
                    elapTime="Elapsed time: "..string.format("%f min (%d sec or %f h)",dtime12_sec/60,dtime12_sec,dtime12_sec/3600)
                    if(skipFlag==0) then resultStr="\tFinished. " end
                    indexNote=indexNote+1
                    stringNote[indexNote]=resultStr..elapTime   
                    print(stringNote[indexNote])
                    for indexNot=1,#stringNote do logFileHd:write(stringNote[indexNot]) end
                end -- countStartFlag End
            end -- PAList End
        end -- f0List End
        time3=os.time()
        dtime03_sec=time3-time0
        modelStr="Current Model takes: "..string.format("%f min (%d sec or %f h)",dtime03_sec/60,dtime03_sec,dtime03_sec/3600)
        print(modelStr)
        logFileHd:write(modelStr)
        line1=lineX()
    else
        line1=lineX()
        line1=lineX()
        line1=lineX()
        line1=lineX()
    end -- gaussIndex>=gaussStartIndex End
end --while End
timeScript1=os.time()
dTimeScript=timeScript1-timeScript0
strTotal="Script Running Time: "..string.format("%f min (%d sec or %f h)",dTimeScript/60,dTimeScript,dTimeScript/3600)
print(strTotal)
logFileHd:write(strTotal)
io.close(logFileHd)
