 

pragma solidity ^0.4.18;



library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        uint256 c = a / b;
         
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract Ownable {
    address public owner;


    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


     
    function Ownable() public {
        owner = msg.sender;
    }


     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }


     
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}

contract ClickableTVToken {
    function balanceOf(address _owner) public view returns (uint256 balance);

    function transfer(address _to, uint256 _value) public returns (bool);
}

contract ClicableTVSale is Ownable {
    using SafeMath for uint256;

     
    ClickableTVToken public token;

     
     
     
    uint256 public presaleStart = 1516492800;  
    uint256 public presaleEnd = 1519862399;  
    uint256 public saleStart = 1519862400;  
    uint256 public saleEnd = 1527811199;  

     
    address public wallet;

     
    uint256 public rate = 10000;

     
    uint256 public weiRaised;

    function ClicableTVSale() public {
        wallet = msg.sender;
    }

    function setToken(ClickableTVToken _token) public onlyOwner {
        token = _token;
    }

     
    function setWallet(address _wallet) public onlyOwner {
        wallet = _wallet;
    }

    function tokenWeiToSale() public view returns (uint256) {
        return token.balanceOf(this);
    }

    function transfer(address _to, uint256 _value) public onlyOwner returns (bool){
        assert(tokenWeiToSale() >= _value);
        token.transfer(_to, _value);
    }


     
    function() external payable {
        buyTokens(msg.sender);
    }

     
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

     
    function buyTokens(address beneficiary) public payable {
        require(beneficiary != address(0));
        require(validPurchase());

        uint256 weiAmount = msg.value;

         
        uint256 tokens = weiAmount.mul(rate);
         
        if (block.timestamp < presaleEnd) tokens = tokens.mul(100).div(75);

         
        weiRaised = weiRaised.add(weiAmount);

        token.transfer(beneficiary, tokens);
        TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

        forwardFunds();
    }

     
     
    function forwardFunds() internal {
        wallet.transfer(msg.value);
    }

     
    function validPurchase() internal view returns (bool) {
        bool presalePeriod = now >= presaleStart && now <= presaleEnd;
        bool salePeriod = now >= saleStart && now <= saleEnd;
        bool nonZeroPurchase = msg.value != 0;
        return (presalePeriod || salePeriod) && nonZeroPurchase;
    }
}