 

pragma solidity ^0.4.25;

 
contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor() public {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0));
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}

 
contract SCUTokenCrowdsale is Ownable {

    uint256 public totalSold;  

    FiatContract public fiat;
    ERC20 public Token;
    address public ETHWallet;
    Whitelist public white;

    uint256 public tokenSold;
    uint256 public tokenPrice;

    uint256 public deadline;
    uint256 public start;

    bool public crowdsaleClosed;

    event Contribution(address from, uint256 amount);

    constructor() public {
        ETHWallet = 0x78D97495f7CA56aC3956E847BB75F825834575A4;
        Token = ERC20(0xBD82A3C93B825c1F93202F9Dd0a120793E029BAD);
        crowdsaleClosed = false;
        white = Whitelist(0xc0b11003708F9d8896c7676fD129188041B7F60B);
        tokenSold = 0;  
        tokenPrice = 20;  
        fiat = FiatContract(0x8055d0504666e2B6942BeB8D6014c964658Ca591);
         
        start = now;
        deadline = now + 80 * 1 days;
    }

    function () public payable {
        require(msg.value>0);
        require(white.isWhitelisted(msg.sender) == true);
        require(!crowdsaleClosed);
        require(now <= deadline && now >= start);
         
         

        uint256 amount = (msg.value / getTokenPrice()) * 1 ether;
        totalSold += (amount / tokenPrice) * 100;

         
        if(tokenSold < 6000000)
        {
        amount = amount + ((amount * 25) / 100);
        }
        else if(tokenSold < 12000000)
        {
        amount = amount + ((amount * 15) / 100);
        }
        else
        {
        amount = amount + ((amount * 10) / 100);
        }

        ETHWallet.transfer(msg.value);
        Token.transferFrom(owner, msg.sender, amount);
        emit Contribution(msg.sender, amount);
    }

    function getTokenPrice() internal view returns (uint256) {
        return getEtherInEuroCents() * tokenPrice / 100;
    }

    function getEtherInEuroCents() internal view returns (uint256) {
        return fiat.EUR(0) * 100;
    }

    function closeCrowdsale() public onlyOwner returns (bool) {
        crowdsaleClosed = true;
        return true;
    }
}

contract Whitelist {
    function isWhitelisted(address _account) public constant returns (bool);

}

contract ERC20 {
    uint public totalSupply;
    function balanceOf(address who) public constant returns (uint);
    function allowance(address owner, address spender) public constant returns (uint);
    function transfer(address to, uint value) public returns (bool ok);
    function transferFrom(address from, address to, uint value) public returns (bool ok);
    function approve(address spender, uint value) public returns (bool ok);
    function mint(address to, uint256 value) public returns (uint256);
}

contract FiatContract {
    function ETH(uint _id) public view returns (uint256);
    function USD(uint _id) public view returns (uint256);
    function EUR(uint _id) public view returns (uint256);
    function GBP(uint _id) public view returns (uint256);
    function updatedAt(uint _id) public view returns (uint);
}