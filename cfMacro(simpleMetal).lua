phi1,phi2,phiStep=0,90,10
theta1,theta2,thetaStep=0,90,10
samplesN=(phi2-phi1)/phiStep*(theta2-theta1)/thetaStep
PAList={0,90}--PolarisationAngle,0 for VV, 90 for HH
index,f0List=0,{}
for f0Cache=0.3e9,2e9,0.17e9 do index=index+1 f0List[index]=f0Cache end
dir = "E:/ZM/0Work/3simuModel/20200416simlationModel/"
-- stepName="1pWedge(1000_100_500)"
-- stepName = "wedge45(1000_250_500)" --*.step
stepName="test"
count,nLoops=0,#PAList*#f0List
time0=os.time()
if(1) then
-- CADFEKO v2019.1-353059 (x64)
app = cf.GetApplication()
project = app.Project
-- New project
project = app:NewProject()

-- Modified solution entity: Model unit
properties = project:GetProperties()
properties.ModelAttributes.Unit = cf.Enums.ModelUnitEnum.Millimetres
project:SetProperties(properties)

-- Scale factor changed from 1 to 0.001
project.ModelAttributes.ExtentsExponent = 5

-- Import Geometry
-- Created geometry
properties = {}
properties.AutoMergeWires = false
properties.AutoStitchFaces = false
properties.ExtrudeEnabled = true
properties.HealingType = cf.Enums.ImportHealingTypeEnum.Standard
properties.ImportScaleFactor = 1000
properties.ImportViasEnabled = true
properties.SimplifyModelEnabled = true
properties.StitchTrimmedFacesEnabled = true
properties.UseInfinitelyThinLayersEnabled = true
properties.UseTwoStepImportEnabled = false
GeometryImporter = project.Importer.Geometry
GeometryImporter:SetProperties(properties)
GeometryImporter:Import(dir..stepName..[[.STEP]])

-- Created solution entity: PlaneWaveSource1
properties = cf.PlaneWave.GetDefaultProperties()
properties.DefinitionMethod = cf.Enums.PlaneWaveDefinitionMethodEnum.Multiple
properties.Label = "PlaneWaveSource1"
properties.StartPhi= phi1
properties.StartTheta= theta1
properties.EndPhi = phi2
properties.EndTheta = theta2
properties.PhiIncrement = phiStep
properties.ThetaIncrement = thetaStep
properties.PolarisationAngle = PA --0 for VV, 90 for HH
PlaneWaveSource1 = project.SolutionConfigurations["StandardConfiguration1"].Sources:AddPlaneWave(properties)

-- Created solution entity: FarField1
properties = cf.FarField.GetDefaultProperties()
properties.CalculationDirection = cf.Enums.FarFieldCalculationDirectionEnum.FromPlaneWave
properties.Label = "FarField1"
properties.Advanced.ExportSettings.ASCIIEnabled = true --export *.ffe
FarField1 = project.SolutionConfigurations["StandardConfiguration1"].FarFields:Add(properties)

-- Updating mesh parameters
MeshSettings = project.Mesher.Settings
MeshSettings.MeshSizeOption=cf.Enums.MeshSizeOptionEnum.Standard

-- Changed settings for geometry entities
geo1 = project.Geometry[1]
-- print(#geo1.Faces)
for i = 1,#geo1.Faces do
    FaceA = geo1.Faces[i]
    faceProperties = FaceA:GetProperties()
    faceProperties.IntegralEquation = cf.Enums.IntegralEquationTypeEnum.CombinedField
    FaceA:SetProperties(faceProperties)
end
-- Solution settings modified
SolverSettings_1 = project.SolutionSettings.SolverSettings
solutionProperties = SolverSettings_1:GetProperties()
solutionProperties.MLFMMACASettings.ModelSolutionSolveType = cf.Enums.ModelSolutionSolveTypeEnum.MLFMM
-- solutionProperties.MLFMMACASettings.ModelSolutionSolveType = cf.Enums.ModelSolutionSolveTypeEnum.None
SolverSettings_1:SetProperties(solutionProperties)
end

for indexF0,f0 in ipairs(f0List) do
-- Set the frequency to single frequency.
StandardConfiguration1 = project.SolutionConfigurations["StandardConfiguration1"]
FrequencyRange1 = StandardConfiguration1.Frequency
properties = FrequencyRange1:GetProperties()
properties.Start = f0
FrequencyRange1:SetProperties(properties)

time1=os.time()
-- Mesh the model
proMesh=project.Mesher:Mesh()
triangleCount = geo1.SimulationMeshInfo.TriangleCount

for indexPA,PA in ipairs(PAList) do --PolarisationAngle,0 for VV, 90 for HH
if(PA==0) 
then
    PAstr="VV"
elseif(PA==90) 
then
    PAstr="HH"
end
count=count+1
fileName = stepName..string.format("(%gM_phi%dto%d_theta%dto%d_%s)",f0/(1e6),phi1,phi2,theta1,theta2,PAstr)
print(count.." of "..nLoops.." "..fileName..".cfx :")
print("\tTriangles: "..triangleCount)

-- Save project
app:SaveAs(dir..fileName)

if(PA~=PAList[1]) then time1=os.time() end
-- RunFEKO
errTimes,skipFlag=0,0
repeat
-- Save project
app:Save()
result=project.Launcher:RunFEKO()
if(result.Succeeded==false) 
then
    errTimes=errTimes+1
    ErrStr=result.Errors
    print("\t"..ErrStr)
    errID=string.sub(ErrStr,string.find(ErrStr,"ERROR   %d*"))
    if(errID=="ERROR   32945")
    then        
        solutionProperties.MLFMMACASettings.ModelSolutionSolveType = cf.Enums.ModelSolutionSolveTypeEnum.None
        SolverSettings_1:SetProperties(solutionProperties)
        print("\tSolution Changed: MLFMM to None")
    else
        resultStr="\tSkipped. "
        skipFlag=1
    end  
end
until(result.Succeeded==true or errTimes>1)
-- Save project
app:Save()
time2=os.time()
dtime12_sec=(time2-time1)
elapTime="Elapsed time: "..string.format("%f min (%d sec or %f h)",dtime12_sec/60,dtime12_sec,dtime12_sec/3600)
if(skipFlag==0)
then
    resultStr="\tFinished. "
end
print(resultStr..elapTime)
print("")
end
end
time3=os.time()
dtime03_sec=time3-time0
print("Total time: "..string.format("%f min (%d sec or %f h)",dtime03_sec/60,dtime_sec03,dtime03_sec/3600))