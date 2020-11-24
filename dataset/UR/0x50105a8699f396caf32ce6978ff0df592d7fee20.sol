 

 

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
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

     
    constructor() internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

     
    function owner() public view returns(address) {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

     
    function isOwner() public view returns(bool) {
        return msg.sender == _owner;
    }

     
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

     
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
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

    mapping (address => uint256) internal _balances;

    mapping (address => mapping (address => uint256)) private _allowed;

    uint256 internal _totalSupply;

     
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
        _transfer(msg.sender, to, value);
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
        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
        _transfer(from, to, value);
        return true;
    }

     
    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0));

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }

     
    function _mint(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.add(value);
        _balances[account] = _balances[account].add(value);
        emit Transfer(address(0), account, value);
    }

}


contract Token is ERC20,Ownable{
    using SafeMath for uint256;
    uint public decimals = 8;
    string public name = "XRK Token";
    string public symbol = "XRK";
    bool public locked = false;
    uint public rate = 12000000;
    uint public rateClam = 1500000;
    address payable public ceoAddress = address(0xE526b6974818576778BdAC1eAC8c15d93D496D3d);
    mapping (address => bool) private preezeArr;
    address[] private holders;
    constructor() public {
        uint _initialSupply = 2000000000000000000;
        _balances[msg.sender] = _initialSupply;
        _totalSupply = _initialSupply;
        holders.push(msg.sender);
        emit Transfer(address(this),msg.sender,_initialSupply);
    }
    event _deposit(address _from, uint256 _eth, uint256 _amount);
    event _clam(address _from, uint256 _eth, uint256 _amount);
    event _withdraw(address _from, uint256 _amount);
    modifier onlyCeoAddress() {
        require(msg.sender == ceoAddress);
        _;
    }
    function() external payable {
        ERC20 erc20 = ERC20(address(this));
        uint256 numtokens = msg.value.mul(rate).mul(10**8).div(10**18);
        require(super.balanceOf(address(this)) >= numtokens);
        erc20.transfer(msg.sender,numtokens);
        ceoAddress.transfer(msg.value);
        emit _deposit(msg.sender, msg.value, numtokens);
    }
    function ClamFree() external payable {
        ERC20 erc20 = ERC20(address(this));
        uint256 numtokens = msg.value.mul(rateClam).mul(10**8).div(10**18);
        require(super.balanceOf(address(this)) >= numtokens);
        erc20.transfer(msg.sender,numtokens);
        ceoAddress.transfer(msg.value);
        emit _clam(msg.sender, msg.value, numtokens);
    }
     
    modifier isValidTransfer() {
        require(!locked);
        _;
    }

    function transfer(address to, uint256 value) public isValidTransfer returns (bool) {
        require(preezeArr[to] != true);
        _addHolder(to);
        return super.transfer(to,value);
    }
    function _addHolder(address holder) internal{
        for(uint i = 0; i < holders.length; i++){
            if(holders[i] == holder){
                return;
            }
        }
        holders.push(holder);
    }
     
    function setLocked(bool _locked) onlyOwner public {
        locked = _locked;
    }
    function withdraw(uint256 _amount, IERC20 _address) onlyCeoAddress public {
        require(super.balanceOf(address(this)) >= _amount);
        _address.transfer(msg.sender,_amount);
        emit _withdraw(msg.sender, _amount);
    }
    function changeCeo(address payable _address) public onlyCeoAddress {
        require(_address != address(0));
        ceoAddress = _address;

    }
    function setRate(uint256 _rate, uint256 _clamFree) onlyOwner public {
        rate = _rate;
        rateClam = _clamFree;
    }

    function mint(address to, uint256 value) onlyOwner public {
        super._mint(to,value);
    }
     
    function setLockedAddress(bool _locked, address to) onlyOwner public {
        preezeArr[to] = _locked;
    }

}