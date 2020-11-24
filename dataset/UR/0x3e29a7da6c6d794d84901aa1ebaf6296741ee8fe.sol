 

pragma solidity ^0.4.24;

 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
     
     
     
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    return a / b;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

 
contract Ownable {

  address public owner;

   
   constructor() public {
    owner = 0xdE6F3798B6364eAF3FCCD73c84d10871c9e6fa8C;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner)public onlyOwner {
    require(newOwner != address(0));
    owner = newOwner;
  }
}


 
interface Token {
  function transfer(address _to, uint256 _value)external returns (bool);
  function balanceOf(address _owner)external view returns (uint256 balance);
}

contract CLTSaleContract is Ownable {

  using SafeMath for uint256;

  Token public token;

  uint256 public raisedETH;  
  uint256 public soldTokens;  
  uint256 public saleMinimum;
  uint256 public price;

  address public beneficiary;

   
   
   
  enum State {Dormant, Active,  Successful }

  State public state;
 
  event ActiveState();
  event DormantState();
  event SuccessfulState();

  event BoughtTokens(
      address indexed who, 
      uint256 tokensBought, 
      uint256 investedETH
      );
  
  constructor() public {

      token =Token(0x848c71FfE323898B03f58c66C9d14766EA4C1DA3); 
      beneficiary = 0xdE6F3798B6364eAF3FCCD73c84d10871c9e6fa8C;
      
      saleMinimum = 5 * 1 ether;
      state = State.Active;
      price = 1330;
}

     
    function () public payable {
        require(msg.value >= saleMinimum);
        require(state == State.Active);
        require(token.balanceOf(this) > 0);
        
        buyTokens(msg.value);
      }



   
  function buyTokens(uint256 _invested) internal   {

    uint256 invested = _invested;
    uint256 numberOfTokens;
    
    numberOfTokens = invested.mul(price);

    
    beneficiary.transfer(msg.value);
    token.transfer(msg.sender, numberOfTokens);
    
    raisedETH = raisedETH.add(msg.value);
    soldTokens = soldTokens.add(numberOfTokens);

    emit BoughtTokens(msg.sender, numberOfTokens, invested);
    
    }
    

   
  function changeRate(uint256 _newPrice) public onlyOwner {
      price = _newPrice;
  }    

   
  function changeSaleMinimum(uint256 _newAmount) public onlyOwner {
      saleMinimum = _newAmount;
  }

   
  function endSale() public onlyOwner {
    require(state == State.Active || state == State.Dormant);
    
    state = State.Successful;
    emit SuccessfulState();
  }
  

    
  function pauseSale() public onlyOwner {
      require(state == State.Active);
      
      state = State.Dormant;
      emit DormantState();
  }
  
   
  function openSale() public onlyOwner {
      require(state == State.Dormant);
      
      state = State.Active;
      emit ActiveState();
  }
  
   
  function emergencyFlush() public onlyOwner {
      token.transfer(owner, token.balanceOf(this));
  }
  

   
  function destroyContract() public onlyOwner {

     
    selfdestruct(owner);
  }

}