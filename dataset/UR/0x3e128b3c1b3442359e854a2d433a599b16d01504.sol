 

pragma solidity ^0.4.18;

 

contract chinainc{
    struct ProjectData{
       string Descript;           
       address dapp_address;      
       string dapp_ens;
       string dapp_jsoninfo;      
       address Owner;             
    }
    
    mapping(string => ProjectData) ProjectDatas;
    address creater;                
    string  public PlatformInformation=""; 
    string  public Hotlist;                
    string[] public AllProjectList; 

     

    modifier OnlyCreater() {  
        require(msg.sender == creater);
         
        _;
    }   
    
    function chinainc() public {
        creater=msg.sender;
    }
    
     
    function __FindProjects(string ProjectName) constant private returns(bool r) {
        if(bytes(ProjectName).length==0) return false;
        if(bytes(ProjectDatas[ProjectName].Descript).length==0) return false;
        return true;
    }
    
        
    function InsertProject(string ProjectName,string Descript,address dapp_address,string dapp_ens,string dapp_jsoninfo,address OwnerAddress) OnlyCreater public 
    {
        if(__FindProjects(ProjectName)==false){
            if(bytes(Descript).length!=0) {
                ProjectDatas[ProjectName].Descript = Descript;
            }else{
                ProjectDatas[ProjectName].Descript = ProjectName;
            }
            ProjectDatas[ProjectName].dapp_address = dapp_address;
            ProjectDatas[ProjectName].dapp_ens = dapp_ens;
            ProjectDatas[ProjectName].dapp_jsoninfo = dapp_jsoninfo;
            ProjectDatas[ProjectName].Owner = OwnerAddress;
            
            AllProjectList.push(ProjectName);
        }else{
             
        }
    }
    
     
    function DeleteProject(string ProjectName) OnlyCreater public{
        delete ProjectDatas[ProjectName];
        uint len = AllProjectList.length; 
        for(uint index=0;index<len;index++){
           if(keccak256(ProjectName)==keccak256(AllProjectList[index])){
               if(index==0){
                    AllProjectList.length = 0;   
               }else{
                    for(uint i=index;i<len-1;i++){
                        AllProjectList[i] = AllProjectList[i+1];
                    }
                    delete AllProjectList[len-1]; 
                    AllProjectList.length--;
               }
               break; 
           } 
        }
    }


    function SetDescript(string ProjectName,string Descript) OnlyCreater public 
    {
        if(__FindProjects(ProjectName)==true){
            if(bytes(Descript).length!=0) {
                ProjectDatas[ProjectName].Descript = Descript;
            }else{
                ProjectDatas[ProjectName].Descript = ProjectName;
            }
        }
    }

    function SetDappinfo(string ProjectName,address dapp_address,string dapp_ens,string dapp_jsoninfo) OnlyCreater public 
    {
        if(__FindProjects(ProjectName)==true){
            ProjectDatas[ProjectName].dapp_address = dapp_address;
            ProjectDatas[ProjectName].dapp_ens = dapp_ens;
            ProjectDatas[ProjectName].dapp_jsoninfo = dapp_jsoninfo;
        }
    }

    function SetOwner(string ProjectName,address Owner) OnlyCreater public 
    {
        if(__FindProjects(ProjectName)==true){
            ProjectDatas[ProjectName].Owner = Owner;
        }
    }

     
    function SetHotLists(string Hotlists)  OnlyCreater public {
        Hotlist = Hotlists;
    }
    
     
    function SetPlatformInformation(string Info) OnlyCreater public{
        PlatformInformation=Info;
    }

     
    function KillContract() OnlyCreater public{
        selfdestruct(creater);
    }
    

     
    function GetDescript(string ProjectName) constant public returns(string) {
        if(__FindProjects(ProjectName)==true){
            return (ProjectDatas[ProjectName].Descript);
        }else{
           return (""); 
        }
    }
    
    function GetDappinfo(string ProjectName) constant public returns(address,string,string) {
        if(__FindProjects(ProjectName)==true){
            return (ProjectDatas[ProjectName].dapp_address,ProjectDatas[ProjectName].dapp_ens,ProjectDatas[ProjectName].dapp_jsoninfo);
        }else{
           return (0,"",""); 
        }
    }

    function GetOwner(string ProjectName) constant public returns(string,address){
        if(__FindProjects(ProjectName)==true){
            return ("项目提供者",ProjectDatas[ProjectName].Owner); 
        }else{
            return ("",0);
        }
    }

}