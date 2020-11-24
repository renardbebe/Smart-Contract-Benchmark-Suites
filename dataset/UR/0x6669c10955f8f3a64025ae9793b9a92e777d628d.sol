 

pragma solidity ^0.4.16;
 
 
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


 
contract ERC20Basic {
    uint256 public totalSupply;
    mapping(address => uint256) balances;
    function balanceOf(address _owner) public constant returns (uint256) { return balances[_owner]; }
     
     
    event Transfer(address indexed from, address indexed to, uint256 value);
}


 
contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    function Ownable() {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address newOwner) onlyOwner public {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}


 
contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;


     
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

     
    modifier whenPaused() {
        require(paused);
        _;
    }

     
    function pause() onlyOwner whenNotPaused public {
        paused = true;
        Pause();
    }

     
    function unpause() onlyOwner whenPaused public {
        paused = false;
        Unpause();
    }
}


contract XBTokenSale is ERC20Basic, Pausable {

    using SafeMath for uint256;
    string public constant name = "XB Token";
    string public constant symbol = "XB";
    uint256 public constant decimals = 18;

     
    address public wallet;

     
    uint256 public constant TOTAL_XB_TOKEN_FOR_PRE_SALE = 2640000 * (10**decimals);  

     
    uint256 public rate = 1250;  

     
    uint256 public presaleSoldTokens = 0;

     
    uint256 public weiRaised;

     
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
    event Mint(address indexed to, uint256 amount);

    function XBTokenSale(address _wallet) public {
        require(_wallet != 0x0);
        wallet = _wallet;
    }


     
    function () whenNotPaused public payable {
        buyTokens(msg.sender);
    }

     
     
    function buyTokens(address beneficiary) whenNotPaused public payable {
        require(beneficiary != 0x0);

        uint256 weiAmount = msg.value;

         
        uint256 tokens = weiAmount.mul(rate);

        require(presaleSoldTokens + tokens <= TOTAL_XB_TOKEN_FOR_PRE_SALE);
        presaleSoldTokens = presaleSoldTokens.add(tokens);

         
        weiRaised = weiRaised.add(weiAmount);

        mint(beneficiary, tokens);
        TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

        forwardFunds();
    }


     
    function mint(address _to, uint256 _amount) internal returns (bool) {
        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        Mint(_to, _amount);
        Transfer(0x0, _to, _amount);
        return true;
    }


     
     
    function forwardFunds() internal {
        wallet.transfer(msg.value);
    }

}