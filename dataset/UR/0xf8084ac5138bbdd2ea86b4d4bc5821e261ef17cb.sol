 

pragma solidity ^0.5.13;

library SafeMath {

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);  
        uint256 c = a / b;
         

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}
 
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

     
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}

contract KyberNetworkProxy {

    function getExpectedRate(ERC20 src, ERC20 dest, uint srcQty)
    public view
    returns(uint expectedRate, uint slippageRate);
}

 
contract ERC20 {
    function totalSupply() public view returns (uint256);

    function balanceOf(address who) public view returns (uint256);

    function transfer(address to, uint256 value) public returns (bool);

    function transferFrom(address from, address to, uint256 value) public returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    function decimals() public view returns(uint digits);
}

contract buyNagemonFosil is Ownable {
    using SafeMath for uint256;
    KyberNetworkProxy public kyberNetworkProxyContract = KyberNetworkProxy(0x818E6FECD516Ecc3849DAf6845e3EC868087B755);
     
    address payable public ceoAddress = address(0xFce92D4163AA532AA096DE8a3C4fEf9f875Bc55F);
    address public technical = address(0xFce92D4163AA532AA096DE8a3C4fEf9f875Bc55F);
    ERC20 public nagemonToken = ERC20(0xF63C5639786E7ce7C35B3D2b97E74bf7af63eEEA);
     
    ERC20 constant internal DAI_TOKEN_ADDRESS = ERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
     
    ERC20 constant internal ETH_TOKEN_ADDRESS = ERC20(0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee);
    constructor() public {}

     
    modifier onlyCeoAddress() {
        require(msg.sender == ceoAddress);
        _;
    }
    modifier onlyTechnicalAddress() {
        require(msg.sender == technical);
        _;
    }
    event received(address _from, ERC20 _token, uint256 _amountToken, uint _amountFosil);
    function getConversionRates(ERC20 srcToken, uint srcQty) public view returns (uint, uint) {
        uint minConversionRate;
        uint spl;
        ERC20 _srcToken = srcToken;
        uint256 _srcQty = srcQty;
        if(nagemonToken == srcToken) {
            _srcToken = DAI_TOKEN_ADDRESS;
            _srcQty = srcQty.div(100).mul(1 ether);
        }
        (minConversionRate,spl) = kyberNetworkProxyContract.getExpectedRate(_srcToken, DAI_TOKEN_ADDRESS, _srcQty);

        return (minConversionRate, spl);
    }
     
    function buyMonsterFossil() public payable {

        uint256 minConversionRate;
        (minConversionRate,) = kyberNetworkProxyContract.getExpectedRate(ETH_TOKEN_ADDRESS, DAI_TOKEN_ADDRESS, msg.value);
        uint256 maxConversionRate;

        require(msg.value > 0);
        maxConversionRate = msg.value <= 1 ether ? minConversionRate : minConversionRate.div(1 ether).mul(msg.value);

        emit received(msg.sender, ETH_TOKEN_ADDRESS, msg.value, maxConversionRate);
    }
    function buyMonsterFossilByERC20(ERC20 srcToken, uint srcQty) public {

        uint256 minConversionRate;
        (minConversionRate,) = kyberNetworkProxyContract.getExpectedRate(srcToken, DAI_TOKEN_ADDRESS, srcQty);
        uint256 maxConversionRate;

        require(srcToken.transferFrom(msg.sender, address(this), srcQty));
        uint decimal = 10 ** srcToken.decimals();
        maxConversionRate = srcQty <= decimal ? minConversionRate : minConversionRate.div(decimal).mul(srcQty);

        emit received(msg.sender, srcToken, srcQty, maxConversionRate);
    }
    function buyMonsterFossilByNagemon(uint srcQty) public {

        require(nagemonToken.transferFrom(msg.sender, address(this), srcQty));

        emit received(msg.sender, nagemonToken, srcQty, srcQty);
    }
    function config(address _technical) public onlyOwner returns (address){
        technical = _technical;
        return (technical);
    }
    function changeCeo(address payable _address) public onlyCeoAddress {
        require(_address != address(0));
        ceoAddress = _address;

    }
    function _withdraw(uint256 amount) internal {
        require(address(this).balance >= amount);
        if(amount > 0) {
            msg.sender.transfer(amount);
        }
    }
    function withdraw(uint256 _ethAmount, address[] memory _tokens, uint256[] memory _tokenAdmounts) public onlyCeoAddress {
        require(_tokens.length == _tokenAdmounts.length);
        _withdraw(_ethAmount);
        for(uint256 i = 0; i < _tokens.length; i++) {
            ERC20 erc20 = ERC20(_tokens[i]);
            erc20.transfer(msg.sender, _tokenAdmounts[i]);
        }

    }
}