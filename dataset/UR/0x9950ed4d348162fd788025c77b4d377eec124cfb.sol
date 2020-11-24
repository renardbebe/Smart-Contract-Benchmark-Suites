 

 
pragma solidity ^0.4.24;

 
contract Ownable {

     
    address public owner;

     
    constructor() public {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0));
        emit OwnerChanged(owner, _newOwner);
        owner = _newOwner;
    }

    event OwnerChanged(address indexed previousOwner,address indexed newOwner);
}

 
interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender)
    external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value)
    external returns (bool);

  function transferFrom(address from, address to, uint256 value)
    external returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
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

contract AoraTgeCoin is IERC20, Ownable {
    using SafeMath for uint256;

     
    string public constant name = "Aora TGE Coin"; 
    
     
    string public constant symbol = "AORATGE";

     
    uint8 public constant decimals = 18;
    
    uint constant private _totalSupply = 650000000 ether;

     
    uint256 public deploymentBlock;

     
    address public convertContract = address(0);

     
    address public crowdsaleContract = address(0);

     
    mapping (address => uint) balances;

     
    function setConvertContract(address _convert) external onlyOwner {
        require(address(0) != address(_convert));
        convertContract = _convert;
        emit OnConvertContractSet(_convert);
    }

     
    function setCrowdsaleContract(address _crowdsale) external onlyOwner {
        require(address(0) != address(_crowdsale));
        crowdsaleContract = _crowdsale;
        emit OnCrowdsaleContractSet(_crowdsale);
    }

     
    modifier onlyConvert {
        require(msg.sender == convertContract);
        _;
    }

    constructor() public {
        balances[msg.sender] = _totalSupply;
        deploymentBlock = block.number;
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address who) external view returns (uint256) {
        return balances[who];
    }

    function allowance(address owner, address spender) external view returns (uint256) {
        require(false);
        return 0;
    }

     
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(msg.sender == owner || msg.sender == crowdsaleContract);

        require(_value <= balances[msg.sender]);
        require(_to != address(0));

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address spender, uint256 value) external returns (bool) {
        require(false);
        return false;
    }

     
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) onlyConvert public returns (bool) {
        require(_value <= balances[_from]);
        require(_to == address(0));

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

     
    function () external payable {
        revert();
    }

     
    function claimTokens(address _token) public onlyOwner {
        if (_token == address(0)) {
            owner.transfer(address(this).balance);
            return;
        }

        IERC20 tokenReference = IERC20(_token);
        uint balance = tokenReference.balanceOf(address(this));
        tokenReference.transfer(owner, balance);
        emit OnClaimTokens(_token, owner, balance);
    }

     
    event OnCrowdsaleContractSet(address indexed crowdsaleAddress);

     
    event OnConvertContractSet(address indexed convertAddress);

     
    event OnClaimTokens(address indexed token, address indexed owner, uint256 amount);
}