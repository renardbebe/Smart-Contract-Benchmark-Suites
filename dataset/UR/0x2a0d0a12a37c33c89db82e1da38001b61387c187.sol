 

pragma solidity >=0.4.21 <0.6.0;

 
 
contract LotteryShop{
     
     
     
    event BuyLottery(address indexed buyer,uint money,uint16 luckNum);
     
    event DrawLottery(address winner,uint money,uint16 luckNum);

     
    mapping(address=>uint) buyMapping;
     
    address payable[]  usrAdrList;

     
    address  manageAdr;
     
    address payable contractAdr;
     
    address payable dataContractAdr;
    constructor() public { 
         
        manageAdr=msg.sender;
         
         
        contractAdr = address(uint160(address(this))); 
         
         
         
         

    }

     
     

     
     
    function ShowInvokerCaiPiao()  public view returns(uint){
        return buyMapping[msg.sender];
    }
    function ShowInvokerBalance()  public view returns(uint){
        return msg.sender.balance;
    }

     
     
    function ShowManageBalance()  public view  returns(uint){
        return manageAdr.balance;
    }

     
     
    function ShowContractMoney() public view returns(uint){
        return contractAdr.balance;
    }
    function ShowContractAdr() public view returns(address payable){
         return contractAdr;
    }
    function ShowManageAdr() public view returns(address){
        return manageAdr;
    }
     
    function getAllUsrAddress() public view returns(address payable[] memory){
        return usrAdrList;
    }
     
    function BuyCaiPiao(uint16 haoMa) payable public {
         
         
         
        require(buyMapping[msg.sender]==0);

         
         
         
         

         
        emit BuyLottery(msg.sender,msg.value,haoMa);

         
        buyMapping[msg.sender] = haoMa;
         
        usrAdrList.push(msg.sender);
    }
     
     
     
    

    function KaiJiangTest()  public view returns(uint){
         
        uint256 luckNum = uint256(keccak256(abi.encodePacked(block.difficulty,now)));
         
        luckNum = luckNum % 3;
        return luckNum;
    }


     
    function KaiJiang() adminOnly public returns(uint){

         
        uint256 luckNum = uint256(keccak256(abi.encodePacked(block.difficulty,now)));
         
        luckNum = luckNum % 3;

         
         
         

        address payable tempAdr;
         
        for(uint32 i=0; i< usrAdrList.length;i++){
            tempAdr = usrAdrList[i];
             
            if(buyMapping[tempAdr] == luckNum){
                 
                emit DrawLottery(tempAdr,(contractAdr.balance),uint16(luckNum));
                 
                
                tempAdr.transfer((contractAdr.balance));
                 
                 
                 

                 
                 
                break;
            }
        }
         
        return luckNum;
    }

     
    function resetData() adminOnly public{
         
        for(uint16 i = 0;i<usrAdrList.length;i++){
            delete buyMapping[usrAdrList[i]];
        }
         
        delete usrAdrList;
    }

     
    function kill() adminOnly public{
         
        selfdestruct(msg.sender);
    }

     
    modifier adminOnly() {
        require(msg.sender == manageAdr);
         
        _;
    }
}