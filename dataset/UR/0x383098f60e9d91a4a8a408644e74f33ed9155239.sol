 

 
pragma solidity^0.4.24;  

interface tokenTransfer {
    function transfer(address receiver, uint amount);
    function transferFrom(address _from, address _to, uint256 _value)returns (bool success);
    function balanceOf(address receiver) returns(uint256);
}

contract Ownable {
  address public owner;
 
    function Ownable () public {
        owner = msg.sender;
    }
 
    modifier onlyOwner {
        require (msg.sender == owner, "OnlyOwner methods called by non-owner.");
        _;
    }
 
     
    function transferOwnership(address newOwner) onlyOwner public {
        if (newOwner != address(0)) {
        owner = newOwner;
      }
    }
  
}
contract BebTreasure is Ownable{
    
    uint256 totalFraction;
    uint256 fractionAmount;
    uint256 totalNumber;
    uint256 numberOfPeriods=201900000; 
    address winAddress;
    uint256 position;
    address minter;
    tokenTransfer public bebTokenTransfer; 
    function BebTreasure(address _tokenAddress){
         bebTokenTransfer = tokenTransfer(_tokenAddress);
          
     }
     struct UserTreasure{
         address addr;
     }
    mapping (address => UserTreasure) public UserTreasures;
    address[] public minersArray;
     
    function treasure(uint256 _amount,uint256 _fraction)public{
        require(totalFraction >= _fraction+totalNumber);
        require(_amount == fractionAmount);
        uint256 sumAmount=_amount*_fraction;
        address _addr = msg.sender;
        UserTreasure storage user=UserTreasures[_addr];
        bebTokenTransfer.transferFrom(_addr,address(this),sumAmount);
        if(_fraction >1){
            for(uint i=0;i<_fraction;i++){
            minersArray.push(_addr);
            }
        }else{
            minersArray.push(_addr);
        }
        user.addr=_addr;
        totalNumber +=_fraction;
    }
     
    function startTreasure(uint256 _totalFraction,uint256 _fractionAmount)onlyOwner {
         
        numberOfPeriods+=1;
        totalFraction=_totalFraction;
        fractionAmount=_fractionAmount* 10 ** 18;
        totalNumber=0;
        delete minersArray;
    }
     
    function openTreasure(uint256 _gamesmul)onlyOwner{
        
        require(totalNumber==totalFraction);
        uint256 random2 = random(block.difficulty+_gamesmul*99/100);
        winAddress = UserTreasures[minersArray[random2]].addr;
        position = random2;
        winAddress.transfer(1 ether);
    }
     function random(uint256 randomyType)   internal returns(uint256 num){
        uint256 random = uint256(keccak256(randomyType,now));
        uint256 randomNum = random%totalNumber;
        return randomNum;
    }
     function getPlayersCount() public view returns(uint256){
        return totalNumber;
    }
     function getWinInfo() public view returns(address,uint256){
        return (winAddress,position);
    }
    function getPeriods() public view returns(uint256){
        return numberOfPeriods;
    }
    function withdrawAmount(uint256 _amount) payable onlyOwner {
        uint256 _amounteth=_amount* 10 ** 18;
       require(this.balance>_amounteth,"Insufficient contract balance"); 
      owner.transfer(_amounteth);
    } 
   function withdrawAmountBeb(uint256 amount) onlyOwner {
        uint256 _amountbeb=amount* 10 ** 18;
        require(getTokenBalance()>_amountbeb,"Insufficient contract balance");
       bebTokenTransfer.transfer(owner,_amountbeb);
    }
    function getTokenBalance() public view returns(uint256){
         return bebTokenTransfer.balanceOf(address(this));
    }
    function()payable{
        
    }
}