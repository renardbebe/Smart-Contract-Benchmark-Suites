 

pragma solidity^0.4.18;

contract Owned {
    address owner;
    
    modifier onlyowner(){
        if (msg.sender == owner) {
            _;
        }
    }

    function Owned() internal {
        owner = msg.sender;
    }
}



contract ethKeepHand is Owned{

    struct DepositItem{
        
        uint depositDate;      
        uint256 depositValue;  
        uint depositTime;      
        uint  valid;           
                               
    }

     mapping(address => DepositItem)  DepositItems;

     event DepositTime(uint time);
     
      
     modifier withdrawable(address adr){

         require(this.balance >= DepositItems[adr].depositValue);
         _;
     }
    
     
    modifier isright()
    {
        require(DepositItems[msg.sender].valid !=1);
        _;
    }



     
    function addDeposit(uint _time) external payable isright{
         
         DepositTime(_time);
         DepositItems[msg.sender].depositDate = now;
         DepositItems[msg.sender].depositValue = msg.value;
         DepositItems[msg.sender].depositTime = _time;
         DepositItems[msg.sender].valid =1;

     }

      
     function withdrawtime() external view returns(uint){
       
       if(DepositItems[msg.sender].depositDate + DepositItems[msg.sender].depositTime > now){
         return DepositItems[msg.sender].depositDate + DepositItems[msg.sender].depositTime - now;
       }
       
        return 0;
     }

      
     function withdrawals() withdrawable(msg.sender) external{

        DepositItems[msg.sender].valid = 0;
        uint256 backvalue = DepositItems[msg.sender].depositValue;
        DepositItems[msg.sender].depositValue = 0;
        msg.sender.transfer(backvalue);


     }
    
      
    function getdepositValue()  external view returns(uint)
     {
        
        return DepositItems[msg.sender].depositValue;
     }
      
     function getvalue() public view returns(uint)
     {
         
         return this.balance;
     }
       
     function  isdeposit() external view returns(uint){

         return DepositItems[msg.sender].valid;
       }


      function() public payable{
          
          revert();
      }
}