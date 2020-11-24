 

pragma solidity 0.5.8;


library SafeMath {

    uint256 constant internal MAX_UINT = 2 ** 256 - 1;  

     
    function mul(uint256 _a, uint256 _b) internal pure returns(uint256) {
        if (_a == 0) {
            return 0;
        }
        require(MAX_UINT / _a >= _b);
        return _a * _b;
    }

     
    function div(uint256 _a, uint256 _b) internal pure returns(uint256) {
        require(_b != 0);
        return _a / _b;
    }

     
    function sub(uint256 _a, uint256 _b) internal pure returns(uint256) {
        require(_b <= _a);
        return _a - _b;
    }

     
    function add(uint256 _a, uint256 _b) internal pure returns(uint256) {
        require(MAX_UINT - _a >= _b);
        return _a + _b;
    }

}


 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

 
contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor () public {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

     
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
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

     
    function pause() public onlyOwner whenNotPaused {
        paused = true;
        emit Pause();
    }

     
    function unpause() public onlyOwner whenPaused {
        paused = false;
        emit Unpause();
    }
}

 
contract CSSSale is Pausable {

    using SafeMath for uint256;

    ERC20 public tokenContract;
    address payable public teamWallet;
    uint256 public rate = 1825;
    uint256 public minValue = 0.1 ether;
    uint256 public maxValue = 0 ether;

    uint256 public minDate = 0;
    uint256 public maxDate = 0;

    uint256 public totalSupply = 0;

    event Buy(address indexed sender, address indexed recipient, uint256 value, uint256 tokens);
    event NewRate(uint256 rate);

    mapping(address => uint256) public records;

    constructor(address _tokenContract, address payable _teamWallet, uint256 _rate, uint256 _minDate, uint256 _maxDate) public {
        require(_tokenContract != address(0));
        require(_teamWallet != address(0));
        tokenContract = ERC20(_tokenContract);
        teamWallet = _teamWallet;
        rate = _rate;
        minDate = _minDate;
        maxDate = _maxDate;
    }


    function () payable external {
        buy(msg.sender);
    }

    function buy(address recipient) payable public whenNotPaused {
        require(msg.value >= minValue);
        require(maxValue == 0 || msg.value <= maxValue);
        require(minDate == 0 || now >= minDate);
        require(maxDate == 0 || now <= maxDate);

        uint256 tokens =  rate.mul(msg.value);

        tokenContract.transferFrom(teamWallet, recipient, tokens);

        records[recipient] = records[recipient].add(tokens);
        totalSupply = totalSupply.add(tokens);

        emit Buy(msg.sender, recipient, msg.value, tokens);

    }


     
    function changeRate(uint256 _rate) public onlyOwner {
        rate = _rate;
        emit NewRate(_rate);
    }

     
    function changeMinValue(uint256 _value) public onlyOwner {
        minValue = _value;
    }
     
    function changeMaxValue(uint256 _value) public onlyOwner {
        maxValue = _value;
    }

         
    function changeMinDate(uint256 _date) public onlyOwner {
        minDate = _date;
    }
     
    function changeMaxDate(uint256 _date) public onlyOwner {
        maxDate = _date;
    }
     
    function changeTeamWallet(address payable _teamWallet) public onlyOwner {
        require(_teamWallet != address(0));
        teamWallet = _teamWallet;
    }

     
    function changeTokenContract(address _tokenContract) public onlyOwner {
        require(_tokenContract != address(0));
        tokenContract = ERC20(_tokenContract);
    }

     
    function withdrawEth() public onlyOwner {
        teamWallet.transfer(address(this).balance);
    }


     
    function withdrawForeignTokens(address _tokenContract) onlyOwner public returns (bool) {
        ERC20Basic token = ERC20Basic(_tokenContract);
        uint256 amount = token.balanceOf(address(this));
        return token.transfer(owner, amount);
    }

}