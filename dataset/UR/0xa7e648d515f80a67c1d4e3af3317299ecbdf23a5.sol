 

pragma solidity 0.4.24;

interface Token {
    function mint(address to, uint256 value) external returns (bool);
}

 
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

contract Investing is Ownable {
    using SafeMath for uint;
    Token public token;
    address public trust;
    address[] public investors;

    struct Investor {
        address investor;
        string currency;
        uint rate;
        uint amount;
        bool redeemed;
        uint timestamp;
		uint tokens;
    }

    mapping(address => Investor[]) public investments;
    mapping(address => uint) public investmentsCount;

    constructor () public {
        owner = msg.sender;
    }

    modifier onlyTrust() {
        require(msg.sender == trust);
        _;
    }

    function makeInvestment(address _investor, string _currency, uint _rate, uint _amount) onlyTrust public returns (bool){
        uint numberOfTokens;
        numberOfTokens = _amount.div(_rate);
        uint _counter = investments[_investor].push(Investor(_investor, _currency, _rate, _amount, false, now, numberOfTokens));
        investmentsCount[_investor] = _counter;
        require(token.mint(_investor, numberOfTokens));
        investors.push(_investor);
        return true;
    }

    function redeem(address _investor, uint _index) public onlyTrust returns (bool) {
        require(investments[_investor][_index].redeemed == false);
        investments[_investor][_index].redeemed = true;
        return true;
    }

    function setTokenContractsAddress(address _tokenContract) public onlyOwner {
        require(_tokenContract != address(0));
        token = Token(_tokenContract);
    }

    function setTrustAddress(address _trust) public onlyOwner {
        require(_trust != address(0));
        trust = _trust;
    }

    function returnInvestors() public view returns (address[]) {
        return investors;
    }
    
    function getInvestmentsCounter(address _investor) public view returns(uint) {
        return investmentsCount[_investor];
    }
    
    function getInvestor(address _investor, uint _index) public view returns(string, uint, uint, bool, uint, uint) {
        return (
            investments[_investor][_index].currency,
            investments[_investor][_index].rate,
            investments[_investor][_index].amount,
            investments[_investor][_index].redeemed,
            investments[_investor][_index].timestamp,
            investments[_investor][_index].tokens
        );
    }
    

    function isRedeemed(address _investor, uint _index) public view returns(bool) {
        return investments[_investor][_index].redeemed;
    }
}