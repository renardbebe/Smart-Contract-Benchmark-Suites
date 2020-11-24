 

 

 

 

 

 

pragma solidity ^0.4.25;
contract SalaryInfo {
    struct User {
        string name;
         
         
         
         
         
         
         
         
         
         
    }
    User[] public users;

    function addUser(string name, string horce_image, string unique_id, string sex,string DOB, string country_name, string Pedigree_name,string color, string owner_name,string breed,string Pedigree_link,string Pedigree_image) public returns(uint) {
        users.length++;
         
        users[users.length-1].name = name;
         
        
        return users.length;
    }
      
      
     function add_medical_records(string record_type, string medical_date, string vaccination,string product,string details) public returns(uint) {
     
     
     
     
     
     
     }
    
    function getUsersCount() public constant returns(uint) {
        return users.length;
    }

    function getUser(uint index) public constant returns(string) {
        return (users[index].name);
    }
}