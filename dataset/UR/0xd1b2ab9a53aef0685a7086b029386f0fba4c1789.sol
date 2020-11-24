 

pragma solidity ^0.4.25;

 
 

 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
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
    owner = msg.sender;
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

contract Crowdsale is Ownable {

  using SafeMath for uint256;

  Token public token;

  uint256 public raisedETH;  
  uint256 public soldTokens;  
  uint256 public saleMinimum = 0.1 * 1 ether;
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
  
  constructor() 
              public 
              {
                token = Token(0x2Ed92cae08B7E24d7C01A11049750498ebCAe8E0);
                beneficiary = msg.sender;
    }

     
    function () public payable {
        require(msg.value >= saleMinimum);
        require(state == State.Active);
        require(token.balanceOf(this) > 0);
        
        buyTokens();
      }

   
  function buyTokens() public payable  {
    
    uint256 invested = msg.value;
    
    uint256 numberOfTokens = invested.mul(price);
    
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

    selfdestruct(owner);

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
  
   
  function tokensAvailable() public view returns(uint256) {
      return token.balanceOf(this);
  }

}