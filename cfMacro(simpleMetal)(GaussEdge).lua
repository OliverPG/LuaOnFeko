nParaProcess=10 --parallel processes
phi1,phi2,phiStep=0,0,10
theta1,theta2,thetaStep=90,90,10
samplesN=(phi2-phi1)/phiStep*(theta2-theta1)/thetaStep
PAList={0,90}--PolarisationAngle,0 for VV, 90 for HH 
index,f0List=0,{}
for f0Cache=0.3e9,2e9,0.425e9 do index=index+1 f0List[index]=f0Cache end
-- for f0Cache=1.490e9,2e9,0.17e9 do index=index+1 f0List[index]=f0Cache end
fekoDir=[[E:\ZM\0Work\3simuModel\20200523GaussModel\]]
stepDir = [[E:\ZM\0Work\3simuModel\20200416simlationModel\]]
stepName=[[1pWedge(1000_100_500)]]
gaussFormulaTxt=[[E:\ZM\0Work\1SimulationReport\CurveCalculation\GaussianStructure\GaussCurve(16)20200529_172254.txt]]
gaussStartIndex=1
countStart=1
countStartFlag=0
-- stepName = "wedge45(1000_250_500)" --*.step
-- stepName="test"
count,nLoops,gaussIndex=0,#PAList*#f0List,0

--abbr:
--pprty property
--prj   project
--PlaneWave     PW
--frequency     frq

lineX=io.lines(gaussFormulaTxt)
line1=lineX()
timeScript0=os.time()
while(line1) do
time0=os.time()
gaussIndex=gaussIndex+1
if gaussIndex>=gaussStartIndex then
count=0
if(1) then --initialize feko and create model
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
importBodies=GeometryImporter:Import(stepDir..stepName..[[.STEP]])
if(1) then-- Create Gaussian head and union
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
-- Created geometry: arbitrary curve "AnalyticalCurve1"
curvePprty = cf.AnalyticalCurve.GetDefaultProperties()
curvePprty.CartesianDescription.U = line2
curvePprty.CartesianDescription.V = line3
curvePprty.CartesianDescription.N = line4
curvePprty.Label = "GaussianCurve"..line1Name
curvePprty.ParametricStart = "0"
curvePprty.ParametricEnd = L
AnalyticalCurve1 = prj.Geometry:AddAnalyticalCurve(curvePprty)
-- Add translate transform
transPprty = cf.Translate.GetDefaultProperties()
transPprty.From.U = "0"
transPprty.From.V = "0"
transPprty.From.N = "0"
transPprty.To.U = "0"
transPprty.To.V = "0"
transPprty.To.N = "250"
Translate2 = AnalyticalCurve1.Transforms:AddTranslate(transPprty)
-- Add a copy and mirror transform
mirrorPprty = cf.Mirror.GetDefaultProperties()
mirrorPprty.Origin.N = "0"
mirrorPprty.Origin.U = "0"
mirrorPprty.Origin.V = "0"
mirrorPprty.Plane = cf.Enums.MirrorPlaneEnum.UV --UV UN VN
mirrorPprty.RotationU = "0"
mirrorPprty.RotationV = "0"
newCurve=AnalyticalCurve1:CopyAndMirror(mirrorPprty)
-- Created geometry: loft 
loftPprty = cf.Loft.GetDefaultProperties()
loftPprty.Label = "gaussFace"
gaussFace=prj.Geometry:Loft(newCurve,AnalyticalCurve1,loftPprty)
-- Created geometry: sweep "Sweep1"
sweepPprty = cf.Sweep.GetDefaultProperties()
sweepPprty.To.V = "1000"
-- Loft1 = project.Geometry["Loft1"]
gaussHead=prj.Geometry:Sweep(gaussFace, sweepPprty)
-- Created geometry: union "Union1"
--wedge = prj.Geometry["1pWedge_1000_250_500_"]
targets=importBodies
table.insert(targets,gaussHead)
unionBody=prj.Geometry:Union(targets)
end

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
-- Paralel ProcessCount 
CompLaunchOpt = prj.Launcher.Settings
launchPprty = CompLaunchOpt:GetProperties()
launchPprty.FEKO.Parallel.NumberOfProcessesEnabled = true
launchPprty.FEKO.Parallel.ProcessCount = nParaProcess
CompLaunchOpt:SetProperties(launchPprty)
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
if not countStartFlag then
if count==countStart then countStartFlag=1 end
end
if countStartFlag then 
fileName = stepName..line1..string.format("(Fre%gM_phi%dto%d_theta%dto%d_Pol%d)",f0/(1e6),phi1,phi2,theta1,theta2,PA)
print(count.." of "..nLoops..string.format(" GaussIndex=%d ",gaussIndex)..fileName..".cfx :")
print("\tTriangles: "..triangleCount)

-- Save project
app:SaveAs(fekoDir..fileName)

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
end
time3=os.time()
dtime03_sec=time3-time0
print("Current Model takes: "..string.format("%f min (%d sec or %f h)",dtime03_sec/60,dtime03_sec,dtime03_sec/3600))
line1=lineX()
else
line1=lineX()
line1=lineX()
line1=lineX()
line1=lineX()
end
-- print(line1)
end
timeScript1=os.time()
dTimeScript=timeScript1-timeScript0
print("Script Running Time: "..string.format("%f min (%d sec or %f h)",dTimeScript/60,dTimeScript,dTimeScript/3600))
