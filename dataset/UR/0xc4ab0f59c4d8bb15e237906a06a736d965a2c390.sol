 

pragma solidity ^0.4.17;

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
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}

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

contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping(address => uint256) balances;

    uint256 totalSupply_;

     
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

     
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

         
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

}

contract StandardToken is ERC20, BasicToken {

    mapping (address => mapping (address => uint256)) internal allowed;


     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

     
    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

     
    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

}

contract LibraToken is StandardToken {

    string public constant name = "LibraToken";  
    string public constant symbol = "LBA";  
    uint8 public constant decimals = 18;  

    uint256 public constant INITIAL_SUPPLY = (10 ** 9) * (10 ** uint256(decimals));

     
    function LibraToken() public {
        totalSupply_ = INITIAL_SUPPLY;
        balances[msg.sender] = INITIAL_SUPPLY;
        Transfer(0x0, msg.sender, INITIAL_SUPPLY);
    }

}

contract AirdropLibraToken is Ownable {
    using SafeMath for uint256;


    uint256 decimal = 10**uint256(18);

     
    uint256 distributedTotal = 0;

    uint256 airdropStartTime;
    uint256 airdropEndTime;

     
    LibraToken private token;

     
    mapping (address => bool) public airdropAdmins;



     
    mapping(address => uint256) public airdropDoneAmountMap;
     
    address[] public airdropDoneList;


     
    event Airdrop(address _receiver, uint256 amount);

    event AddAdmin(address _admin);

    event RemoveAdmin(address _admin);

    event UpdateEndTime(address _operator, uint256 _oldTime, uint256 _newTime);



    modifier onlyOwnerOrAdmin() {
        require(msg.sender == owner || airdropAdmins[msg.sender]);
        _;
    }


    function addAdmin(address _admin) public onlyOwner {
        airdropAdmins[_admin] = true;
        AddAdmin(_admin);
    }

    function removeAdmin(address _admin) public onlyOwner {
        if(isAdmin(_admin)){
            airdropAdmins[_admin] = false;
            RemoveAdmin(_admin);
        }
    }


    modifier onlyWhileAirdropPhaseOpen {
        require(block.timestamp > airdropStartTime && block.timestamp < airdropEndTime);
        _;
    }


    function AirdropLibraToken(
        ERC20 _token,
        uint256 _airdropStartTime,
        uint256 _airdropEndTime
    ) public {
        token = LibraToken(_token);
        airdropStartTime = _airdropStartTime;
        airdropEndTime = _airdropEndTime;

    }


    function airdropTokens(address _recipient, uint256 amount) public onlyOwnerOrAdmin onlyWhileAirdropPhaseOpen {
        require(amount > 0);

        uint256 lbaBalance = token.balanceOf(this);

        require(lbaBalance >= amount);

        require(token.transfer(_recipient, amount));


         
        airdropDoneList.push(_recipient);

         
        uint256 airDropAmountThisAddr = 0;
        if(airdropDoneAmountMap[_recipient] > 0){
            airDropAmountThisAddr = airdropDoneAmountMap[_recipient].add(amount);
        }else{
            airDropAmountThisAddr = amount;
        }

        airdropDoneAmountMap[_recipient] = airDropAmountThisAddr;

        distributedTotal = distributedTotal.add(amount);

        Airdrop(_recipient, amount);

    }

     
    function airdropTokensBatch(address[] receivers, uint256[] amounts) public onlyOwnerOrAdmin onlyWhileAirdropPhaseOpen{
        require(receivers.length > 0 && receivers.length == amounts.length);
        for (uint256 i = 0; i < receivers.length; i++){
            airdropTokens(receivers[i], amounts[i]);
        }
    }

    function transferOutBalance() public onlyOwner view returns (bool){
        address creator = msg.sender;
        uint256 _balanceOfThis = token.balanceOf(this);
        if(_balanceOfThis > 0){
            LibraToken(token).approve(this, _balanceOfThis);
            LibraToken(token).transferFrom(this, creator, _balanceOfThis);
            return true;
        }else{
            return false;
        }
    }

     
    function balanceOfThis() public view returns (uint256){
        return token.balanceOf(this);
    }

     
    function getDistributedTotal() public view returns (uint256){
        return distributedTotal;
    }


    function isAdmin(address _addr) public view returns (bool){
        return airdropAdmins[_addr];
    }

    function updateAirdropEndTime(uint256 _newEndTime) public onlyOwnerOrAdmin {
        UpdateEndTime(msg.sender, airdropEndTime, _newEndTime);
        airdropEndTime = _newEndTime;
    }

     
    function getDoneAddresses() public constant returns (address[]){
        return airdropDoneList;
    }

     
    function getDoneAirdropAmount(address _addr) public view returns (uint256){
        return airdropDoneAmountMap[_addr];
    }

}