 

pragma solidity ^0.4.21;

 
contract Ownable {
    address public owner;


    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
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
contract IQUASaleMint {
    function mintProxyWithoutCap(address _to, uint256 _amount) public;
    function mintProxy(address _to, uint256 _amount) public;
}



 
contract QuasaCoinExchanger is Ownable {
    using SafeMath for uint256;

     
    address public wallet;

     
    uint256 public rate;

     
    IQUASaleMint public icoSmartcontract;

    function QuasaCoinExchanger() public {

        owner = msg.sender;

         
        rate = 3000;
        wallet = 0x373ae730d8c4250b3d022a65ef998b8b7ab1aa53;
        icoSmartcontract = IQUASaleMint(0x48299b98d25c700e8f8c4393b4ee49d525162513);
    }


    function setRate(uint256 _rate) onlyOwner public  {
        rate = _rate;
    }


     
     
     

     
    function () external payable {
        buyTokens(msg.sender);
    }

     
    function buyTokens(address _beneficiary) public payable {

        uint256 _weiAmount = msg.value;

        require(_beneficiary != address(0));
        require(_weiAmount != 0);

         
        uint256 _tokenAmount = _weiAmount.mul(rate);

        icoSmartcontract.mintProxyWithoutCap(_beneficiary, _tokenAmount);

        wallet.transfer(_weiAmount);
    }

}