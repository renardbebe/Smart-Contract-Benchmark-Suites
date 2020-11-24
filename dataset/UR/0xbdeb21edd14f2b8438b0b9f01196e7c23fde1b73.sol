 

pragma solidity 0.5.0;
pragma experimental ABIEncoderV2;

 
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
     
     
     
        return a / b;
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

     
contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowed;

    uint256 private _totalSupply;
    string public name;
    string public symbol;
    uint8 public decimals;

     
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

     
    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

     
    function allowance(
        address owner,
        address spender
    )
        public
        view
        returns (uint256)
    {
        return _allowed[owner][spender];
    }


     
    function transfer(address to, uint256 value) public returns (bool) {
        require(value <= _balances[msg.sender]);
        require(to != address(0));

        _balances[msg.sender] = _balances[msg.sender].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(msg.sender, to, value);
        return true;
    }

     
    function approve(address spender, uint256 value) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

     
    function transferFrom(
        address from,
        address to,
        uint256 value
    )
        public
        returns (bool)
    {
        require(value <= _balances[from]);
        require(value <= _allowed[from][msg.sender]);
        require(to != address(0));

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
        emit Transfer(from, to, value);
        return true;
    }

     
    function increaseAllowance(
        address spender,
        uint256 addedValue
    )
        public
        returns (bool)
    {
        require(spender != address(0));

        _allowed[msg.sender][spender] = (
        _allowed[msg.sender][spender].add(addedValue));
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

     
    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    )
        public
        returns (bool)
    {
        require(spender != address(0));

        _allowed[msg.sender][spender] = (
        _allowed[msg.sender][spender].sub(subtractedValue));
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

     
    function _mint(address account, uint256 amount) internal {
        require(account != address(0));
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

     
    function _burn(address account, uint256 amount) internal {
        require(account != address(0));
        require(amount <= _balances[account]);

        _totalSupply = _totalSupply.sub(amount);
        _balances[account] = _balances[account].sub(amount);
        emit Transfer(account, address(0), amount);
    }

     
    function _burnFrom(address account, uint256 amount) internal {
        require(amount <= _allowed[account][msg.sender]);

         
         
        _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(
        amount);
        _burn(account, amount);
    }

    function burnFrom(address account, uint256 amount) public {
        _burnFrom(account, amount);
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

    function getOwner() public view returns (address) {
        return owner;
    }

    function getOwnerStatic(address ownableContract) internal view returns (address) {
        bytes memory callcodeOwner = abi.encodeWithSignature("getOwner()");
        (bool success, bytes memory returnData) = address(ownableContract).staticcall(callcodeOwner);
        require(success, "input address has to be a valid ownable contract");
        return parseAddr(returnData);
    }

    function getTokenVestingStatic(address tokenFactoryContract) internal view returns (address) {
        bytes memory callcodeTokenVesting = abi.encodeWithSignature("getTokenVesting()");
        (bool success, bytes memory returnData) = address(tokenFactoryContract).staticcall(callcodeTokenVesting);
        require(success, "input address has to be a valid TokenFactory contract");
        return parseAddr(returnData);
    }


    function parseAddr(bytes memory data) public pure returns (address parsed){
        assembly {parsed := mload(add(data, 32))}
    }




}

 
contract TokenVesting is Ownable{

    using SafeMath for uint256;

    event Released(address indexed token, address vestingBeneficiary, uint256 amount);
    event LogTokenAdded(address indexed token, address vestingBeneficiary, uint256 vestingPeriodInWeeks);

    uint256 constant public WEEKS_IN_SECONDS = 1 * 7 * 24 * 60 * 60;

    struct VestingInfo {
        address vestingBeneficiary;
        uint256 releasedSupply;
        uint256 start;
        uint256 duration;
    }

    mapping(address => VestingInfo) public vestingInfo;

     
    function addToken
    (
        address _token,
        address _vestingBeneficiary,
        uint256 _vestingPeriodInWeeks
    )
    external
    onlyOwner
    {
        vestingInfo[_token] = VestingInfo({
            vestingBeneficiary : _vestingBeneficiary,
            releasedSupply : 0,
            start : now,
            duration : uint256(_vestingPeriodInWeeks).mul(WEEKS_IN_SECONDS)
        });
        emit LogTokenAdded(_token, _vestingBeneficiary, _vestingPeriodInWeeks);
    }

     

    function release
    (
        address _token
    )
    external
    {
        uint256 unreleased = releaseableAmount(_token);
        require(unreleased > 0);
        vestingInfo[_token].releasedSupply = vestingInfo[_token].releasedSupply.add(unreleased);
        bool success = ERC20(_token).transfer(vestingInfo[_token].vestingBeneficiary, unreleased);
        require(success, "transfer from vesting to beneficiary has to succeed");
        emit Released(_token, vestingInfo[_token].vestingBeneficiary, unreleased);
    }

     
    function releaseableAmount
    (
        address _token
    )
    public
    view
    returns(uint256)
    {
        return vestedAmount(_token).sub(vestingInfo[_token].releasedSupply);
    }

     

    function vestedAmount
    (
        address _token
    )
    public
    view
    returns(uint256)
    {
        VestingInfo memory info = vestingInfo[_token];
        uint256 currentBalance = ERC20(_token).balanceOf(address(this));
        uint256 totalBalance = currentBalance.add(info.releasedSupply);
        if (now >= info.start.add(info.duration)) {
            return totalBalance;
        } else {
            return totalBalance.mul(now.sub(info.start)).div(info.duration);
        }

    }


    function getVestingInfo
    (
        address _token
    )
    external
    view
    returns(VestingInfo memory)
    {
        return vestingInfo[_token];
    }


}