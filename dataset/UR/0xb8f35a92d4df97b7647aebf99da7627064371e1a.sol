 

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
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}

contract XRRtoken {
    function balanceOf(address _owner) public view returns (uint256 balance);

    function transfer(address _to, uint256 _value) public returns (bool);
}

contract XRRsale is Ownable {
    using SafeMath for uint256;

    address public wallet = 0x3398BdC73b3e245187aAe7b231e453c0089AA04e;
    XRRtoken public token = XRRtoken(0x0e75235647330B5e13cAD9115254C4B8E16272F8);
    address public frozenVaults = 0xc684Bf3b56Ca914b7B0670845092420A661963F7;

    uint256 public totalRaiseWei = 0;
    uint256 public totalTokenRaiseWei = 0;

     
    uint PreSaleStart = 1521504000;

    uint PreSaleEnd = 1522886400;


     
    uint ICO1 = 1523491200;
    uint ICO2 = 1524096000;
    uint ICO3 = 1524700800;
    uint ICO4 = 1525305600;
    uint ICOend = 1528502400;

    function XRRsale() public {

    }

    function currentPrice() public view returns (uint256){
        if (now >= PreSaleStart && now < PreSaleEnd) return 26000;
        else if (now >= ICO1 && now < ICO2) return 12000;
        else if (now >= ICO2 && now < ICO3) return 11500;
        else if (now >= ICO3 && now < ICO4) return 11000;
        else if (now >= ICO4 && now < ICOend) return 10500;
        else return 0;
    }


    function checkAmount(uint256 _amount) public view returns (bool){
        if (now >= PreSaleStart && now < PreSaleEnd) return _amount >= 1 ether;
        else if (now >= ICO1 && now < ICO2) return _amount >= 0.1 ether;
        else if (now >= ICO2 && now < ICO3) return _amount >= 0.1 ether;
        else if (now >= ICO3 && now < ICO4) return _amount >= 0.1 ether;
        else if (now >= ICO4 && now < ICOend) return _amount >= 0.1 ether;
        else return false;
    }


    function tokenTosale() public view returns (uint256){
        return token.balanceOf(this);
    }

    function tokenWithdraw() public onlyOwner {
        require(tokenTosale() > 0);
        token.transfer(owner, tokenTosale());
    }

    function() public payable {
        require(msg.value > 0);
        require(checkAmount(msg.value));
        require(currentPrice() > 0);

        totalRaiseWei = totalRaiseWei.add(msg.value);
        uint256 tokens = currentPrice().mul(msg.value);
        require(tokens <= tokenTosale());

        totalTokenRaiseWei = totalTokenRaiseWei.add(tokens);
        token.transfer(msg.sender, tokens);
        wallet.transfer(msg.value);
    }

    function sendTokens(address _to, uint256 _value) public onlyOwner {
        require(_value > 0);
        require(_value <= tokenTosale());
        require(currentPrice() > 0);
        require(tokenTosale() >= _value);

        uint256 amount = _value.div(currentPrice());
        totalRaiseWei = totalRaiseWei.add(amount);
        totalTokenRaiseWei = totalTokenRaiseWei.add(_value);
        token.transfer(_to, _value);
    }

    function finishSale() public onlyOwner {
        uint256 tokensToFrozen = 18000000 ether;
        require(tokenTosale() >= tokensToFrozen);
         
        token.transfer(frozenVaults, tokensToFrozen);
    }
}