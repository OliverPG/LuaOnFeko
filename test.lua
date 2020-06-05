
feko = cf or pf
form = feko.Form.New("Demonstration")
label = feko.FormLabel.New("Hello world!")
form:Add(label)
form:Run()
-- app=cf.GetApplication()
-- app:NewProject()