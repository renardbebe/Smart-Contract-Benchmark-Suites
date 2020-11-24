 

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
library SafeMath {

  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

}

 
contract Owned {
     
    address public owner;

     
    function setOwner(address _owner) onlyOwner
    { owner = _owner; }

     
    modifier onlyOwner { if (msg.sender != owner) throw; _; }
}

contract TRMCrowdsale is Owned {
    using SafeMath for uint;

    event Print(string _message, address _msgSender);

    uint public ETHUSD = 100000;  
    address manager = 0xf5c723B7Cc90eaA3bEec7B05D6bbeBCd9AFAA69a;
    address ETHUSDdemon;
    address public multisig = 0xc2CDcE18deEcC1d5274D882aEd0FB082B813FFE8;
    address public addressOfERC20Token = 0x8BeF0141e8D078793456C4b74f7E60640f618594;
    ERC20 public token;

    uint public startICO = now;
    uint public endICO = 1519776000;  
    uint public endPostICO = 1522454400;  

    uint public tokenIcoUsdCentPrice = 550;
    uint public tokenPostIcoUsdCentPrice = 650;

    uint public bonusWeiAmount = 29900000000000000000;  
    uint public smallBonusPercent = 27;
    uint public bigBonusPercent = 37;


    function TRMCrowdsale(){
        owner = msg.sender;
        token = ERC20(addressOfERC20Token);
        ETHUSDdemon = msg.sender;

    }

    function tokenBalance() constant returns (uint256) {
        return token.balanceOf(address(this));
    }

 
    function setAddressOfERC20Token(address _addressOfERC20Token) onlyOwner {
        addressOfERC20Token = _addressOfERC20Token;
        token = ERC20(addressOfERC20Token);

    }

    function transferToken(address _to, uint _value) returns (bool) {
        require(msg.sender == manager);
        return token.transfer(_to, _value);
    }

    function() payable {
        doPurchase();
    }

    function doPurchase() payable {
        require(now >= startICO && now < endPostICO);

        require(msg.value > 0);

        uint sum = msg.value;

        uint tokensAmount;

        if(now < endICO){
            tokensAmount = sum.mul(ETHUSD).div(tokenIcoUsdCentPrice).div(10000000000);
        } else {
            tokensAmount = sum.mul(ETHUSD).div(tokenPostIcoUsdCentPrice).div(10000000000);
        }


         
        if(sum < bonusWeiAmount){
           tokensAmount = tokensAmount.mul(100+smallBonusPercent).div(100);
        } else{
           tokensAmount = tokensAmount.mul(100+bigBonusPercent).div(100);
        }

        if(tokenBalance() > tokensAmount){
            require(token.transfer(msg.sender, tokensAmount));
            multisig.transfer(msg.value);
        } else {
            manager.transfer(msg.value);
            Print("Tokens will be released manually", msg.sender);
        }


    }

    function setETHUSD( uint256 _newPrice ) {
        require((msg.sender == ETHUSDdemon)||(msg.sender == manager));
        ETHUSD = _newPrice;
    }

    function setBonus( uint256 _bonusWeiAmount, uint256 _smallBonusPercent, uint256 _bigBonusPercent ) {
        require(msg.sender == manager);

        bonusWeiAmount = _bonusWeiAmount;
        smallBonusPercent = _smallBonusPercent;
        bigBonusPercent = _bigBonusPercent;
    }
    
    function setETHUSDdemon(address _ETHUSDdemon) 
    { 
        require(msg.sender == manager);
        ETHUSDdemon = _ETHUSDdemon; 
        
    }

}