 

pragma solidity ^0.4.23;

 


 
 
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
 

 
 
contract Ownable {
    address public owner;


    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );


     
    constructor() public {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(owner);
        owner = address(0);
    }

     
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0));
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }


}
 




 

 
contract UChainToken is ERC20 {
    using SafeMath for uint256;

     
    string constant public name = 'UChain Token';
    string constant public symbol = 'UCN';
    uint8 constant public decimals = 18;
    uint256 constant public decimalFactor = 10 ** uint(decimals);

    uint256 public totalSupply;

     
    bool public isMintingFinished = false;
    mapping(address => bool) public admins;

     
    struct Vesting {
        uint256 vestedUntil;
        uint256 vestedAmount;
    }

    mapping(address => Vesting) public vestingEntries;

     
    bool public isTransferEnabled = false;
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowances;


     
    event MintFinished();
    event Mint(address indexed _beneficiary, uint256 _value);
    event MintVested(address indexed _beneficiary, uint256 _value);
    event AdminRemoved(address indexed _adminAddress);
    event AdminAdded(address indexed _adminAddress);

     
    constructor() public {
        admins[msg.sender] = true;
    }

     

     
    function totalSupply() public view returns (uint256) {
        return totalSupply - balances[address(0)];
    }

     
    function balanceOf(address _tokenOwner) public view returns (uint256) {
        return balances[_tokenOwner];
    }

     
    function allowance(address _tokenOwner, address _spender) public view returns (uint256) {
        return allowances[_tokenOwner][_spender];
    }

     

     
    modifier onlyAdmin() {
        require(admins[msg.sender]);
        _;
    }

     
    function removeAdmin(address _adminAddress) public onlyAdmin {
        delete admins[_adminAddress];
        emit AdminRemoved(_adminAddress);
    }

     
    function addAdmin(address _adminAddress) public onlyAdmin {
        admins[_adminAddress] = true;
        emit AdminAdded(_adminAddress);
    }

     
    function isAdmin(address _adminAddress) public view returns (bool) {
        return admins[_adminAddress];
    }

     

    function mint(address _beneficiary, uint256 _value) public onlyAdmin returns (bool)  {
        require(!isMintingFinished);
        totalSupply = totalSupply.add(_value);
        balances[_beneficiary] = balances[_beneficiary].add(_value);
        emit Mint(_beneficiary, _value);
        emit Transfer(address(0), _beneficiary, _value);
        return true;
    }

    function bulkMint(address[] _beneficiaries, uint256[] _values) public onlyAdmin returns (bool)  {
        require(_beneficiaries.length == _values.length);
        for (uint256 i = 0; i < _beneficiaries.length; i = i.add(1)) {
            require(mint(_beneficiaries[i], _values[i]));
        }
        return true;
    }

    function mintVested(uint256 _vestedUntil, address _beneficiary, uint256 _value) public onlyAdmin returns (bool) {
        require(mint(_beneficiary, _value));
        vestingEntries[_beneficiary] = Vesting(_vestedUntil, _value);
        emit MintVested(_beneficiary, _value);
        return true;
    }

    function bulkMintVested(uint256 _vestedUntil, address[] _beneficiaries, uint256[] _values) public onlyAdmin returns (bool)  {
        require(_beneficiaries.length == _values.length);
        for (uint256 i = 0; i < _beneficiaries.length; i = i.add(1)) {
            require(mintVested(_vestedUntil, _beneficiaries[i], _values[i]));
        }
        return true;
    }

     
    function finishMinting() public onlyAdmin {
        isMintingFinished = true;
    }

     
    function getNonVestedBalanceOf(address _tokenOwner) public view returns (uint256) {
        if (block.timestamp < vestingEntries[_tokenOwner].vestedUntil) {
            return balances[_tokenOwner].sub(vestingEntries[_tokenOwner].vestedAmount);
        } else {
            return balances[_tokenOwner];
        }
    }

     

     
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(isTransferEnabled);
        require(_to != address(0));
        require(_value <= getNonVestedBalanceOf(msg.sender));

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);

        emit Transfer(msg.sender, _to, _value);
        return true;
    }


     

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(isTransferEnabled);
        require(_to != address(0));
        require(_value <= getNonVestedBalanceOf(_from));
        require(_value <= allowances[_from][msg.sender]);

        allowances[_from][msg.sender] = allowances[_from][msg.sender].sub(_value);
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);

        emit Transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function setIsTransferEnabled(bool _isTransferEnabled) public onlyAdmin {
        isTransferEnabled = _isTransferEnabled;
    }
}