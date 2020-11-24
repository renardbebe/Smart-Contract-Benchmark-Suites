 

pragma solidity ^0.4.18;

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

contract ERC20Basic {
    function totalSupply() public view returns (uint256);

    function balanceOf(address who) public view returns (uint256);

    function transfer(address to, uint256 value) public returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);

    function transferFrom(address from, address to, uint256 value) public returns (bool);

    function approve(address spender, uint256 value) public returns (bool);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract AsetToken is ERC20 {

}

contract AsetSale is Ownable {
    using SafeMath for uint256;

    AsetToken public token;

    uint256 public price;

    address public wallet;

    uint256 public totalRice = 0;
    uint256 public totalTokenRice = 0;

    function AsetSale() public {
         
         
        price = 1300;
         
        wallet = msg.sender;
    }

    function setToken(AsetToken _token) public onlyOwner {
        token = _token;
    }

    function tokensToSale() public view returns (uint256) {
        return token.balanceOf(this);
    }

    function setPrice(uint256 _price) public onlyOwner {
        price = _price;
    }

    function setWallet(address _wallet) public onlyOwner {
        wallet = _wallet;
    }

    function withdrawTokens() public onlyOwner {
        require(address(token) != address(0));
        require(tokensToSale() > 0);
        token.transfer(wallet, tokensToSale());
    }


    function() public payable {
        require(msg.value > 0);
        require(address(token) != address(0));
        require(tokensToSale() > 0);

        uint256 tokensWei = msg.value.mul(price);
        tokensWei = withBonus(tokensWei);
        token.transfer(msg.sender, tokensWei);
        wallet.transfer(msg.value);
        totalRice = totalRice.add(msg.value);
        totalTokenRice = totalTokenRice.add(tokensWei);
    }

    function sendToken(address _to, uint256 tokensWei)public onlyOwner{
        require(address(token) != address(0));
        require(tokensToSale() > 0);

        uint256 amountWei = tokensWei.div(price);
        token.transfer(_to, tokensWei);
        totalRice = totalRice.add(amountWei);
        totalTokenRice = totalTokenRice.add(tokensWei);
    }

    function withBonus(uint256 _amount) internal pure returns(uint256) {
        if(_amount <= 500 ether) return _amount;
        else if(_amount <= 1000 ether) return _amount.mul(105).div(100);
        else if(_amount <= 2000 ether) return _amount.mul(107).div(100);
        else if(_amount <= 5000 ether) return _amount.mul(110).div(100);
        else if(_amount <= 10000 ether) return _amount.mul(115).div(100);
        else return _amount.mul(120).div(100);
    }
}