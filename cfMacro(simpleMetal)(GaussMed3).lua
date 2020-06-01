nParaProcess=6 --parallel processes
phi1,phi2,phiStep=0,0,10
theta1,theta2,thetaStep=90,90,10
samplesN=(phi2-phi1)/phiStep*(theta2-theta1)/thetaStep
PAList={0,90}--PolarisationAngle,0 for VV, 90 for HH 
index,f0List=0,{}
for f0Cache=0.3e9,2e9,0.425e9 do index=index+1 f0List[index]=f0Cache end
-- for f0Cache=1.490e9,2e9,0.17e9 do index=index+1 f0List[index]=f0Cache end
fekoDir=[[E:\ZM\0Work\3simuModel\20200530GaussMed3\]]
stepDir = [[E:\ZM\0Work\3simuModel\20200416simlationModel\]]
stepName=[[1pWedge(1000_100_500)]]--.STEP
gaussFormulaTxt=[[E:\ZM\0Work\1SimulationReport\CurveCalculation\GaussianStructure\GaussCurve(16)20200529_172254.txt]]
medTxts={[[E:\ZM\0Work\1SimulationReport\YP60A.txt]],[[E:\ZM\0Work\1SimulationReport\YP60B.txt]],[[E:\ZM\0Work\1SimulationReport\YP60C.txt]]}
Q=3/4
nMed=3
CFIntFaces={"Face1","Face2","Face4","Face5","Face6_1","Face6_2"}
colors={"#F706FF","#3806FF","#05C9FF","#03FF2D","#FF8E72","#FFD2C9","#B7FFC2","#B4A5FF","#FFA5F3"}
count,nLoops,gaussIndex=0,#PAList*#f0List,0
-------------------------Parameters Setting End---------------------------------------------
--abbr:
--pprty property
--prj   project
--PlaneWave     PW
--frequency     frq

-- Add medium properties
medPprty,medName,med={},{},{}
for index=1,#medTxts,1 do
medPprty[index]=cf.Dielectric.GetDefaultProperties()
medPprty[index].Colour=colors[index]
medPprty[index].DielectricModelling.DefinitionMethod=cf.Enums.MediumDielectricDefinitionMethodEnum.FrequencyList
medPprty[index].MagneticModelling.DefinitionMethod=cf.Enums.MediumDielectricDefinitionMethodEnum.FrequencyList
lineMedX=io.lines(medTxts[index])
line1=lineMedX()
countMedLines=0
while(line1) do
countMedLines=countMedLines+1
strFunc=line1:gmatch("[+-]?[0-9]*[%.]?[0-9]+")
freCache=strFunc()
epsR=strFunc()
tanDE=strFunc()
mueR=strFunc()
tanDM=strFunc()
medPprty[index].DielectricModelling.FrequencyPoints[countMedLines] = {}
medPprty[index].DielectricModelling.FrequencyPoints[countMedLines].Frequency=freCache
medPprty[index].DielectricModelling.FrequencyPoints[countMedLines].RelativePermittivity=epsR
medPprty[index].DielectricModelling.FrequencyPoints[countMedLines].LossTangent=tanDE
medPprty[index].MagneticModelling.FrequencyPoints[countMedLines] = {}
medPprty[index].MagneticModelling.FrequencyPoints[countMedLines].Frequency =freCache
medPprty[index].MagneticModelling.FrequencyPoints[countMedLines].RelativePermeability =mueR
medPprty[index].MagneticModelling.FrequencyPoints[countMedLines].LossTangent =tanDM
line1=lineMedX()
end
medPprty[index].MassDensity = "1000"
medName[index]=medTxts[index]:sub(-medTxts[index]:reverse():find([[\]])+1,-medTxts[index]:reverse():find([[%.]])-1)
medPprty[index].Label = medName[index]
-- med[index] = prj.Media:AddDielectric(medPprty[index])
end
---Add Gaussian curve Formula 
lineX=io.lines(gaussFormulaTxt)
line1=lineX()
timeScript0=os.time()
while(line1) do
time0=os.time()
gaussIndex=gaussIndex+1
count=0
if(1) then --initialize feko and create model
-- CADFEKO v2019.1-353059 (x64)
app = cf.GetApplication()
prj = app.Project
-- New project
prj = app:NewProject()
-- Add new Medium
for index=1,#medTxts,1 do
    med[index] = prj.Media:AddDielectric(medPprty[index])
end
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
-- Create Gaussian head and union
if(1) then
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
-- Create Gaussian curve
curvePprty = cf.AnalyticalCurve.GetDefaultProperties()
curvePprty.CartesianDescription.U = line2
curvePprty.CartesianDescription.V = line3
curvePprty.CartesianDescription.N = line4
curvePprty.Label = "GaussianCurve"..line1Name
curvePprty.ParametricStart = "0"
curvePprty.ParametricEnd = L
gaussCurve = prj.Geometry:AddAnalyticalCurve(curvePprty)
-- Transform Gaussian curve
transPprty = cf.Translate.GetDefaultProperties()
transPprty.From.U = "0"
transPprty.From.V = "0"
transPprty.From.N = "0"
transPprty.To.U = "0"
transPprty.To.V = "0"
transPprty.To.N = "250"
Translate2 = gaussCurve.Transforms:AddTranslate(transPprty)
-- Copy and mirror Gaussian curve
mirrorPprty = cf.Mirror.GetDefaultProperties()
mirrorPprty.Origin.N = "0"
mirrorPprty.Origin.U = "0"
mirrorPprty.Origin.V = "0"
mirrorPprty.Plane = cf.Enums.MirrorPlaneEnum.UV --UV UN VN
mirrorPprty.RotationU = "0"
mirrorPprty.RotationV = "0"
gaussCurveMir=gaussCurve:CopyAndMirror(mirrorPprty)
-- Duplicate Gaussian Curves and Union
gaussCurve1=gaussCurve:Duplicate()
gaussCurveMir1=gaussCurveMir:Duplicate()
curTargets={gaussCurve1,gaussCurveMir1}
-- printlist(curTargets)
-- table.insert(curTargets,gaussCurveMir1)
unionGaussCurve=prj.Geometry:Union(curTargets)
-- Loft Gaussian curves to face
loftPprty = cf.Loft.GetDefaultProperties()
loftPprty.Label = "gaussFace"
gaussFace=prj.Geometry:Loft(gaussCurveMir,gaussCurve,loftPprty)
-- Sweep Face to Gaussian Head
sweepPprty = cf.Sweep.GetDefaultProperties()
sweepPprty.To.V = "1000"
gaussHead=prj.Geometry:Sweep(gaussFace, sweepPprty)
-- union Gaussian Head And 1pWedge
MetalTargets=importBodies
table.insert(MetalTargets,gaussHead)
unionMetal=prj.Geometry:Union(MetalTargets)
-- Sweep Gaussian curves to hook surface
gaussCurFace=prj.Geometry:Sweep(unionGaussCurve,sweepPprty)--,gaussCurve
-- Create Elliptic Part
ellipPprty = cf.EllipticArc.GetDefaultProperties()
ellipPprty.LocalWorkplane.VVector.Y = "0"
ellipPprty.LocalWorkplane.VVector.Z = "1"
ellipPprty.Centre.N = "0"
ellipPprty.Centre.U = "0"
ellipPprty.Centre.V = "0"
ellipPprty.StartAngle = "0"
ellipPprty.EndAngle = "90"
ellipPprty.RadiusU = tonumber(L)/(1-Q)
ellipPprty.RadiusV = H
ellipPprty.Label = "EllipticArc1"
EllipticArc1 = prj.Geometry:AddEllipticArc(ellipPprty)
-- Copy and Mirror EllipticArc1
EllipticArc2=EllipticArc1:CopyAndMirror(mirrorPprty)
-- Loft EllipticArcs
loftPprty.Label = "EllipticFace"
ellipFace=prj.Geometry:Loft(EllipticArc1,EllipticArc2,loftPprty)
-- Sweep ellipFace
ellipticBody=prj.Geometry:Sweep(ellipFace,sweepPprty)
-- Create n Part Mediums And Assign Medium
medParts={}
transPprty.From.U = "0"
transPprty.From.V = "0"
transPprty.From.N = "0"
transPprty.To.V = "0"
transPprty.To.N = "0"
sweepXPprty = cf.Sweep.GetDefaultProperties()
dMed=Q*tonumber(L)/(1-Q)/nMed
for index=2,nMed,1 do
    gaussCurFc=gaussCurFace:Duplicate()
    transPprty.To.U = (index-1)*dMed
    gaussCurFc.Transforms:AddTranslate(transPprty)
    if index==nMed then
        sweepXPprty.To.U = dMed*5
    else
        sweepXPprty.To.U = dMed
    end
    gaussMedPart=prj.Geometry:Sweep(gaussCurFc,sweepXPprty)
    newEllipticBody=ellipticBody:Duplicate()
    medParts[index]=prj.Geometry:Intersect({gaussMedPart,newEllipticBody})
    for i=1,#medParts[index].Regions,1 do
        regPprty=medParts[index].Regions[i]:GetProperties()
        regPprty.Medium=med[index]        
        medParts[index].Regions[i]:SetProperties(regPprty)
    end
end
    sweepXPprty.To.U = dMed
    gaussMedPart=prj.Geometry:Sweep(gaussCurFace,sweepXPprty)
    medParts[1]=prj.Geometry:Intersect({gaussMedPart,ellipticBody})
    for i=1,#medParts[1].Regions,1 do
        regPprty=medParts[1].Regions[i]:GetProperties()
        regPprty.Medium=med[1]        
        medParts[1].Regions[i]:SetProperties(regPprty)
    end
end
-- Union All medium parts
unionMed=prj.Geometry:Union(medParts)
-- Union Metal And Medium parts
unionAll=prj.Geometry:Union({unionMed,unionMetal})
-- Simplify unionAll
simPprty = {}
simPprty.EdgeSettings = {}
simPprty.FaceSettings = {}
simPprty.PointSettings = {}
simPprty.RegionSettings = {}
simPprty.EdgeSettings.KeepWithLocalMeshSizeEnabled = true
simPprty.EdgeSettings.RemoveInDielectricRegions = true
simPprty.EdgeSettings.RemoveInMetalRegions = true
simPprty.EdgeSettings.RemoveOnDielectricFaces = true
simPprty.EdgeSettings.RemoveOnMetalFaces = true
simPprty.FaceSettings.KeepWithLocalMeshSizeEnabled = true
simPprty.FaceSettings.RemoveBetweenEqualDielectricRegions = true
simPprty.FaceSettings.RemoveBetweenEqualMetalRegions = true
simPprty.FaceSettings.RemoveBetweenShellRegions = true
simPprty.Included = true
-- simPprty.Label = "SimUnion"
simPprty.Locked = false
simPprty.PointSettings.RemoveRedundant = true
simPprty.RegionSettings.KeepWithLocalMeshSizeEnabled = true
simPprty.Visible = true
-- Union1 = project.Geometry["Union1"]
simUnion=prj.Geometry:Simplify(unionAll, simPprty)
-- CombinedField for Faces in Table CFIntFaces
for i = 1,#CFIntFaces do
    FaceA = simUnion.Faces[CFIntFaces[i]]
    facePprty= FaceA:GetProperties()
    facePprty.IntegralEquation = cf.Enums.IntegralEquationTypeEnum.CombinedField
    FaceA:SetProperties(facePprty)
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
-- Paralel ProcessCount 
CompLaunchOpt = prj.Launcher.Settings
launchPprty = CompLaunchOpt:GetProperties()
launchPprty.FEKO.Parallel.NumberOfProcessesEnabled = true
launchPprty.FEKO.Parallel.ProcessCount = nParaProcess
CompLaunchOpt:SetProperties(launchPprty)
end
for indexF0,f0 in ipairs(f0List) do
-- Solution Method
SolverSettings_1 = prj.SolutionSettings.SolverSettings
solutionProperties = SolverSettings_1:GetProperties()
solutionProperties.MLFMMACASettings.ModelSolutionSolveType = cf.Enums.ModelSolutionSolveTypeEnum.MLFMM
-- solutionProperties.MLFMMACASettings.ModelSolutionSolveType = cf.Enums.ModelSolutionSolveTypeEnum.None
SolverSettings_1:SetProperties(solutionProperties)
-- Set single frequency
StandardConfiguration1 = prj.SolutionConfigurations["StandardConfiguration1"]
FrequencyRange1 = StandardConfiguration1.Frequency
frqPprty = FrequencyRange1:GetProperties()
frqPprty.Start = f0
FrequencyRange1:SetProperties(frqPprty)

time1=os.time()
-- Mesh the model
proMesh=prj.Mesher:Mesh()
triangleCount = simUnion.SimulationMeshInfo.TriangleCount

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
time3=os.time()
dtime03_sec=time3-time0
print("Current Model takes: "..string.format("%f min (%d sec or %f h)",dtime03_sec/60,dtime03_sec,dtime03_sec/3600))
line1=lineX()
end
timeScript1=os.time()
dTimeScript=timeScript1-timeScript0
print("Script Running Time: "..string.format("%f min (%d sec or %f h)",dTimeScript/60,dTimeScript,dTimeScript/3600))
