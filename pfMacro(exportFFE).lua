phi1,phi2,phiStep=0,90,10
theta1,theta2,thetaStep=0,90,10
PA=90 --PolarisationAngle,0 for VV, 90 for HH
f0=1e9

samplesN=(phi2-phi1)/phiStep*(theta2-theta1)/thetaStep
-- print(samplesN)

dir = "E:/ZM/0Work/3simuModel/20200416simlationModel/"
fileName = "wedge45(1_0.25_0.5)(1G_phi0to90_theta0to90)"
stepName = "wedge45(1_0.25_0.5)" --*.step

app = pf.GetApplication()
app:NewProject()
app:OpenFile(dir..fileName..".fek")
config = app.Models[1].Configurations[1]
config:ExportFarFields(dir..fileName..".ffe",pf.Enums.FarFieldsExportTypeEnum.RCS,samplesN)
print("Export "..dir..fileName..".ffe")
