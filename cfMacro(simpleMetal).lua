phi1,phi2,phiStep=0,90,10
theta1,theta2,thetaStep=0,90,10
samplesN=(phi2-phi1)/phiStep*(theta2-theta1)/thetaStep
PAList={90}--PolarisationAngle,0 for VV, 90 for HH 0,
index,f0List=0,{}
for f0Cache=0.3e9,2e9,0.17e9 do index=index+1 f0List[index]=f0Cache end
-- for f0Cache=1.490e9,2e9,0.17e9 do index=index+1 f0List[index]=f0Cache end
dir = "E:/ZM/0Work/3simuModel/20200416simlationModel/"
stepName="1pWedge(1000_100_500)"
-- stepName = "wedge45(1000_250_500)" --*.step
-- stepName="test"
count,nLoops=0,#PAList*#f0List

--abbr
--pprty property
--prj   project
--PlaneWave     PW
--frequency     frq
time0=os.time()
if(1) then
-- CADFEKO v2019.1-353059 (x64)
app = cf.GetApplication()
prj = app.Project
-- New project
prj = app:NewProject()

-- Modified solution entity: Model unit
prjPprty = prj:GetProperties()
prjPprty.ModelAttributes.Unit = cf.Enums.ModelUnitEnum.Millimetres
prj:SetProperties(prjPprty)

-- Scale factor changed from 1 to 0.001
prj.ModelAttributes.ExtentsExponent = 5

-- Import Geometry
-- Created geometry
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
GeometryImporter = prj.Importer.Geometry
GeometryImporter:SetProperties(importPprty)
GeometryImporter:Import(dir..stepName..[[.STEP]])

-- Created solution entity: PlaneWaveSource1
PwPprty = cf.PlaneWave.GetDefaultProperties()
PwPprty.DefinitionMethod = cf.Enums.PlaneWaveDefinitionMethodEnum.Multiple
PwPprty.Label = "PlaneWaveSource1"
PwPprty.StartPhi= phi1
PwPprty.StartTheta= theta1
PwPprty.EndPhi = phi2
PwPprty.EndTheta = theta2
PwPprty.PhiIncrement = phiStep
PwPprty.ThetaIncrement = thetaStep
PwPprty.PolarisationAngle = 0 --0 for VV, 90 for HH
PlaneWaveSource1 = prj.SolutionConfigurations["StandardConfiguration1"].Sources:AddPlaneWave(PwPprty)

-- Created solution entity: FarField1
farfieldPprty = cf.FarField.GetDefaultProperties()
farfieldPprty.CalculationDirection = cf.Enums.FarFieldCalculationDirectionEnum.FromPlaneWave
farfieldPprty.Label = "FarField1"
farfieldPprty.Advanced.ExportSettings.ASCIIEnabled = true --export *.ffe
FarField1 = prj.SolutionConfigurations["StandardConfiguration1"].FarFields:Add(farfieldPprty)

-- Updating mesh parameters
MeshSettings = prj.Mesher.Settings
MeshSettings.MeshSizeOption=cf.Enums.MeshSizeOptionEnum.Standard

-- Changed settings for geometry entities
geo1 = prj.Geometry[1]
-- print(#geo1.Faces)
for i = 1,#geo1.Faces do
    FaceA = geo1.Faces[i]
    faceProperties = FaceA:GetProperties()
    faceProperties.IntegralEquation = cf.Enums.IntegralEquationTypeEnum.CombinedField
    FaceA:SetProperties(faceProperties)
end
end

for indexF0,f0 in ipairs(f0List) do
-- Solution settings modified
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

time1=os.time()
-- Mesh the model
proMesh=prj.Mesher:Mesh()
triangleCount = geo1.SimulationMeshInfo.TriangleCount

for indexPA,PA in ipairs(PAList) do --PolarisationAngle,0 for VV, 90 for HH
if(PA==0) 
then
    PAstr="VV"
elseif(PA==90) 
then
    PAstr="HH"
end
PwPprty.PolarisationAngle = PA
PlaneWaveSource1:SetProperties(PwPprty)
count=count+1
fileName = stepName..string.format("(Fre%gM_phi%dto%d_theta%dto%d_%s)",f0/(1e6),phi1,phi2,theta1,theta2,PAstr)
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
result=prj.Launcher:RunFEKO()
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
print("Total time: "..string.format("%f min (%d sec or %f h)",dtime03_sec/60,dtime03_sec,dtime03_sec/3600))
