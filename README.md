# LuaOnFeko
## Lua5.1 on Feko2019

---
## Main Funtion
1. Import model file (*.step or others) to CADFEKO.
2. Based set about Unit (m or mm), Space Extend, Incidence Direction, Farfield Request, Meshing Standard, Slover Set.
3. Other set about Integrate Equation, Exported file (*.ffe).
4. Run and save the CFX file according to a group of frequency points and polarisations specified.
5. Try to solve Errors that may occur according to the Error ID if there are, or skip current task.
6. Print current running file/task name (*.cfx). Print Errors if thers are. Print the time cosuming information for each loop and all tasks.