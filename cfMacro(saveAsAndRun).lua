nParaProcess=8 --parallel processes
phi1,phi2,phiStep=0,90,5
theta1,theta2,thetaStep=0,90,5
-- f1,f2,fStep=0.3e9,2e9,0.425e9 --1.490e9,2e9,0.17e9
f1,f2,fStep=0.3e9,2e9,0.4625e9 --1.490e9,2e9,0.17e9
PAList={0,90}--PolarisationAngle,0 for VV, 90 for HH 
fekoDir=[[E:\ZM\0Work\3simuModel\20200416simlationModel\1pWedge(1000_100_500)\]] --Where the New Cfx save in
cfxFile = [[E:\ZM\0Work\3simuModel\20200416simlationModel\1pWedge(1000_100_500).cfx]] -- which Cfx as initial file 
countStart=1
-----------------------------------------------------------------------------------------------------------------------
index,f0List=0,{}
for f0Cache=f1,f2,fStep do index=index+1 f0List[index]=f0Cache end
f0Last=-1
samplesN=(phi2-phi1)/phiStep*(theta2-theta1)/thetaStep
cfxShortName=cfxFile:sub(-cfxFile:reverse():find([[\]])+1,-cfxFile:reverse():find([[%.]])-1)
cfxDirName=cfxFile:sub(1,-cfxFile:reverse():find([[\]]))
-- print(cfxShortName)
-- print(cfxDirName)
countStartFlag=false
mkdirStr1="md "..fekoDir
os.execute(mkdirStr1)
logFileName=[[lua.log]]
logLongName=fekoDir..logFileName
count,nLoops=0,#PAList*#f0List
logFileHd=io.open(logLongName,"w")
stringNote={}
--abbr:
--pprty property
--prj   project
--PlaneWave     PW
--frequency     frq
 if(1) then --initialize feko
    --Created solution entity: PlaneWaveSource1
    PwPprty = cf.PlaneWave.GetDefaultProperties()
    PwPprty.DefinitionMethod = cf.Enums.PlaneWaveDefinitionMethodEnum.Multiple
    PwPprty.Label = "PlaneWaveSource1"
    PwPprty.StartPhi= phi1
    PwPprty.StartTheta= theta1
    PwPprty.EndPhi = phi2
    PwPprty.EndTheta = theta2
    PwPprty.PhiIncrement = phiStep
    PwPprty.ThetaIncrement = thetaStep
    -- 	PwPprty.PolarisationAngle = 0 --0 for VV, 90 for HH
    -- 	PlaneWaveSource1 = prj.SolutionConfigurations["StandardConfiguration1"].Sources:AddPlaneWave(PwPprty)	
    --  Created solution entity: FarField1
    farfieldPprty = cf.FarField.GetDefaultProperties()
    farfieldPprty.CalculationDirection = cf.Enums.FarFieldCalculationDirectionEnum.FromPlaneWave
    farfieldPprty.Label = "FarField1"
    farfieldPprty.Advanced.ExportSettings.ASCIIEnabled = true --export *.ffe
    -- 	FarField1 = prj.SolutionConfigurations["StandardConfiguration1"].FarFields:Add(farfieldPprty)	
end
time0=os.time()
count=0
for indexF0,f0 in ipairs(f0List) do	
    for indexPA,PA in ipairs(PAList) do
        time1=os.time()	
        count=count+1
	if not countStartFlag then
            if count==countStart then countStartFlag=true end
	end
        if countStartFlag then
            fileName = cfxShortName..string.format("(Fre%gM_phi%dto%ddphi%d_theta%dto%ddtheta%d_Pol%d)",f0/(1e6),phi1,phi2,phiStep,theta1,theta2,thetaStep,PA)
            if count==countStart then -- if it's the first run
           	 -- Open project
           	 app = cf.GetApplication()
                 prj = app:OpenFile(cfxFile)                 		
                 -- Save project as
                 app:SaveAs(fekoDir..fileName)   
           	 -- Modified solution entity: Model unit
           	 prjPprty = prj:GetProperties()
           	 prjPprty.ModelAttributes.Unit = cf.Enums.ModelUnitEnum.Millimetres
           	 prj:SetProperties(prjPprty)
           	 -- Scale factor changed from 1 to 0.001
           	 prj.ModelAttributes.ExtentsExponent = 5          	
                 -- Set PlaneWaveSource
                 PwPprty.PolarisationAngle = PA
                 PlaneWaveSource1 = prj.SolutionConfigurations["StandardConfiguration1"].Sources
                 if #PlaneWaveSource1==0 then
                    PlaneWaveSource1 = PlaneWaveSource1:AddPlaneWave(PwPprty)
                 else                    
                    PlaneWaveSource1[1]:SetProperties(PwPprty)
                 end
           	 -- PlaneWaveSource1:SetProperties(PwPprty)
                 FarField1 = prj.SolutionConfigurations["StandardConfiguration1"].FarFields
                 if #FarField1==0 then
                    FarField1 = FarField1:Add(farfieldPprty)
                 else 
                    FarField1[1]:SetProperties(farfieldPprty) 
                 end
           	 -- Paralel ProcessCount 
           	 CompLaunchOpt = prj.Launcher.Settings
           	 launchPprty = CompLaunchOpt:GetProperties()
           	 launchPprty.FEKO.Parallel.NumberOfProcessesEnabled = true
           	 launchPprty.FEKO.Parallel.ProcessCount = nParaProcess
           	 CompLaunchOpt:SetProperties(launchPprty)  
            else --if Not the first run                    		
                 -- Save project as
                 app:SaveAs(fekoDir..fileName)                	
                 -- Set PlaneWaveSource   
                 PwPprty.PolarisationAngle = PA
                 if PlaneWaveSource1[1]~=nil then
                    PlaneWaveSource1[1]:SetProperties(PwPprty)
                 else
                    PlaneWaveSource1:SetProperties(PwPprty)
                 end
            end -- The first run or not End
            if f0~=f0Last then
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
            stringNote[indexNote]=count.." of "..nLoops.." "..fileName..".cfx :"
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
io.close(logFileHd)
