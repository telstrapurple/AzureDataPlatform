CREATE VIEW pbi.vw_Workspaces AS 

SELECT 
	[Id]                    
    ,[Name]                  
    ,[IsReadOnly]            
    ,[IsOnDedicatedCapacity] 
    ,[CapacityId]            
    ,[Description]           
    ,[Type]                  
    ,[State]                 
    ,[IsOrphaned]            
FROM 
	pbi.Workspaces