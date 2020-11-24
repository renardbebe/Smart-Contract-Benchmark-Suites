 

pragma solidity 0.5.4;


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

interface AbcInterface {
    function decimals() external view returns (uint8);
    function tokenFallback(address _from, uint _value, bytes calldata _data) external;
    function transfer(address _to, uint _value) external returns (bool);
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


contract StandardToken {
    using SafeMath for uint256;

    mapping(address => uint256) internal balances;

    mapping(address => mapping(address => uint256)) internal allowed;

    uint256 public totalSupply;

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

     
    function balanceOf(address _owner) public view returns(uint256) {
        return balances[_owner];
    }

     
    function allowance(address _owner, address _spender) public view returns(uint256) {
        return allowed[_owner][_spender];
    }

     
    function transfer(address _to, uint256 _value) public returns(bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns(bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns(bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

     
    function increaseApproval(address _spender, uint256 _addedValue) public returns(bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

     
    function decreaseApproval(address _spender, uint256 _subtractedValue) public returns(bool) {
        uint256 oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue >= oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function _burn(address account, uint256 value) internal {
        require(account != address(0));
        totalSupply = totalSupply.sub(value);
        balances[account] = balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

     
    function _burnFrom(address account, uint256 value) internal {
         
         
        allowed[account][msg.sender] = allowed[account][msg.sender].sub(value);
        _burn(account, value);
    }

}


contract BurnableToken is StandardToken {

     
    function burn(uint256 value) public {
        _burn(msg.sender, value);
    }

     
    function burnFrom(address from, uint256 value) public {
        _burnFrom(from, value);
    }
}


 
contract PausableToken is StandardToken, Pausable {
    function transfer(address to, uint256 value) public whenNotPaused returns (bool) {
        return super.transfer(to, value);
    }

    function transferFrom(address from, address to, uint256 value) public whenNotPaused returns (bool) {
        return super.transferFrom(from, to, value);
    }

    function approve(address spender, uint256 value) public whenNotPaused returns (bool) {
        return super.approve(spender, value);
    }

    function increaseApproval(address spender, uint256 addedValue) public whenNotPaused returns (bool success) {
        return super.increaseApproval(spender, addedValue);
    }

    function decreaseApproval(address spender, uint256 subtractedValue) public whenNotPaused returns (bool success) {
        return super.decreaseApproval(spender, subtractedValue);
    }
}

contract LockableToken is PausableToken {
	struct LockInfo {
		uint256 amount;
		uint256 releaseTime;
	}

	mapping(address => LockInfo[]) public lockDetail;
	mapping(address => uint256) public transferLocked;

	event LockToken(address indexed benefit, uint256 amount, uint256 releasetime);
	event ReleaseToken(address indexed benefit, uint256 amount);
	
	 
	function transferAndLock(address to, uint256 value, uint256 lockdays) public whenNotPaused returns (bool) {
		release(msg.sender);
		require(to != address(0) && value != 0 && lockdays != 0);
		uint256 _releaseTime = now.add(lockdays.mul(1 days));
		lockDetail[to].push(LockInfo({amount:value, releaseTime:_releaseTime}));
		balances[msg.sender] = balances[msg.sender].sub(value);
		transferLocked[to] = transferLocked[to].add(value);
		emit Transfer(msg.sender, to, value);
		emit LockToken(to, value, _releaseTime);
		return true;
	}

	 
    function transfer(address to, uint256 value) public returns (bool) {
		release(msg.sender);
        return super.transfer(to, value);
    }

	 
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        release(from);
        return super.transferFrom(from, to, value);
    }

	 
	function release(address benefit) public whenNotPaused {
		uint256 len = lockDetail[benefit].length;
		if( len == 0) return;
		uint256 totalReleasable = 0;
		for(uint256 i = 0; i < len; i = i.add(1)){
			LockInfo memory tmp = lockDetail[benefit][i];
			if(tmp.releaseTime != 0 && now >= tmp.releaseTime){
				totalReleasable = totalReleasable.add(tmp.amount);
				delete lockDetail[benefit][i];
			}
		}
		if(totalReleasable == 0) return;
		balances[benefit] = balances[benefit].add(totalReleasable);
		transferLocked[benefit] = transferLocked[benefit].sub(totalReleasable);
		if(transferLocked[benefit] == 0)
		delete lockDetail[benefit];
		emit ReleaseToken(benefit, totalReleasable);

	}

	 
	function releasableTokens(address benefit) public view returns(uint256) {
		uint256 len = lockDetail[benefit].length;
		if( len == 0) return 0;
		uint256 releasable = 0;
		for(uint256 i = 0; i < len; i = i.add(1)){
			LockInfo memory tmp = lockDetail[benefit][i];
			if(tmp.releaseTime != 0 && now >= tmp.releaseTime){
				releasable = releasable.add(tmp.amount);
			}
		}	
		return releasable;	
	}
}

contract Token is LockableToken, BurnableToken {
    string public name;  
    string public symbol;  
    uint8 public decimals;

    constructor(string memory _name, string memory _symbol, uint8 _decimals) public {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }
}

contract IOAEXBDR is Token {
    struct Trx {
        bool executed;
        address from;
        uint256 value;
        address[] signers;
    }

    mapping(address => bool) public isSigner;
    mapping(uint256 => Trx) public exchangeTrx;
    address public AbcInstance;   
    uint256 public requestSigners = 2;   
    uint256 public applyCounts = 0;   
    mapping(address => uint256) public exchangeLock;

    event SetSigner(address indexed signer,bool isSigner);   
    event ApplyExchangeToken(address indexed from,uint256 value,uint256 trxSeq);   
    event ConfirmTrx(address indexed signer,uint256 indexed trxSeq);   
    event CancleConfirmTrx(address indexed signer,uint256 indexed trxSeq);   
    event CancleExchangeRequest(address indexed signer,uint256 indexed trxSeq);   
    event TokenExchange(address indexed from,uint256 value,bool AbcExchangeBDR);  
    event Mint(address indexed target,uint256 value);

    modifier onlySigner() {
        require(isSigner[msg.sender]);
        _;
    }
     
    constructor(string memory _name, string memory _symbol, uint8 _decimals) Token(_name,_symbol,_decimals) public {
    }

     
    function transfer(address _to,uint256 _value) public returns (bool success) {
        require(_to != AbcInstance,"can't transfer to AbcToken address directly");
        return super.transfer(_to,_value);
    }

     
    function transferFrom(address _from, address _to,uint256 _value) public returns (bool success) {
        require(_to != AbcInstance,"can't transfer to AbcToken address directly");
        return super.transferFrom(_from,_to,_value);
    }

     
    function transferAndLock(address _to, uint256 _value, uint256 _lockdays) public returns (bool success) {
        require(_to != AbcInstance,"can't transfer to AbcToken address directly");
        return super.transferAndLock(_to,_value,_lockdays);
    }   

     
    function setAbcInstance(address _abc) public onlyOwner {
        require(_abc != address(0));
        AbcInstance = _abc;
    }

     
    function setSigners(address[] memory _signers,bool _addSigner) public onlyOwner {
        for(uint256 i = 0;i< _signers.length;i++){
            require(_signers[i] != address(0));
            isSigner[_signers[i]] = _addSigner;
            emit SetSigner(_signers[i],_addSigner);
        }
    }

     
    function setrequestSigners(uint256 _requestSigners) public onlyOwner {
        require(_requestSigners != 0);
        requestSigners = _requestSigners;
    }

     
    function isConfirmer(uint256 _trxSeq,address _signer) public view returns (bool) {
        require(exchangeTrx[_trxSeq].from != address(0),"trxSeq not exist");
        for(uint256 i = 0;i < exchangeTrx[_trxSeq].signers.length;i++){
            if(exchangeTrx[_trxSeq].signers[i] == _signer){
                return true;
            }
        }
        return false;
    }

     
    function getConfirmersLengthOfTrx(uint256 _trxSeq) public view returns (uint256) {
        return exchangeTrx[_trxSeq].signers.length;
    }

     
    function getConfirmerOfTrx(uint256 _trxSeq,uint256 _index) public view returns (address) {
        require(_index < getConfirmersLengthOfTrx(_trxSeq),"out of range");
        return exchangeTrx[_trxSeq].signers[_index];
    }

     
    function applyExchangeToken(uint256 _value) public whenNotPaused returns (uint256) {
        uint256 trxSeq = applyCounts;
        require(exchangeTrx[trxSeq].from == address(0),"trxSeq already exist");
        require(balances[msg.sender] >= _value);
        exchangeTrx[trxSeq].executed = false;
        exchangeTrx[trxSeq].from = msg.sender;
        exchangeTrx[trxSeq].value = _value;
        applyCounts = applyCounts.add(1);
        balances[address(this)] = balances[address(this)].add(_value);
        balances[exchangeTrx[trxSeq].from] = balances[exchangeTrx[trxSeq].from].sub(_value);
        exchangeLock[exchangeTrx[trxSeq].from] = exchangeLock[exchangeTrx[trxSeq].from].add(_value);
        emit ApplyExchangeToken(exchangeTrx[trxSeq].from,exchangeTrx[trxSeq].value,trxSeq);
        emit Transfer(msg.sender,address(this),_value);
        return trxSeq;
    }

     
    function confirmExchangeTrx(uint256 _trxSeq) public onlySigner {
        require(exchangeTrx[_trxSeq].from != address(0),"_trxSeq not exist");
        require(exchangeTrx[_trxSeq].signers.length < requestSigners,"trx already has enough signers");
        require(exchangeTrx[_trxSeq].executed == false,"trx already executed");
        require(isConfirmer(_trxSeq, msg.sender) == false,"signer already confirmed");
        exchangeTrx[_trxSeq].signers.push(msg.sender);
        emit ConfirmTrx(msg.sender, _trxSeq);
    }

     
    function cancelConfirm(uint256 _trxSeq) public onlySigner {
        require(exchangeTrx[_trxSeq].from != address(0),"_trxSeq not exist");
        require(isConfirmer(_trxSeq, msg.sender),"Signer didn't confirm");
        require(exchangeTrx[_trxSeq].executed == false,"trx already executed");
        uint256 len = exchangeTrx[_trxSeq].signers.length;
        for(uint256 i = 0;i < len;i++){
            if(exchangeTrx[_trxSeq].signers[i] == msg.sender){
                exchangeTrx[_trxSeq].signers[i] = exchangeTrx[_trxSeq].signers[len.sub(1)] ;
                exchangeTrx[_trxSeq].signers.length --;
                break;
            }
        }
        emit CancleConfirmTrx(msg.sender,_trxSeq);
    }

     
    function cancleExchangeRequest(uint256 _trxSeq) public {
        require(exchangeTrx[_trxSeq].from != address(0),"_trxSeq not exist");
        require(exchangeTrx[_trxSeq].executed == false,"trx already executed");
        require(isSigner[msg.sender] || exchangeTrx[_trxSeq].from == msg.sender);
        balances[address(this)] = balances[address(this)].sub(exchangeTrx[_trxSeq].value);
        balances[exchangeTrx[_trxSeq].from] = balances[exchangeTrx[_trxSeq].from].add(exchangeTrx[_trxSeq].value);
        exchangeLock[exchangeTrx[_trxSeq].from] = exchangeLock[exchangeTrx[_trxSeq].from].sub(exchangeTrx[_trxSeq].value);
        delete exchangeTrx[_trxSeq];
        emit CancleExchangeRequest(msg.sender,_trxSeq);
        emit Transfer(address(this),exchangeTrx[_trxSeq].from,exchangeTrx[_trxSeq].value);
    }

     
    function executeExchangeTrx(uint256 _trxSeq) public whenNotPaused{
        address from = exchangeTrx[_trxSeq].from;
        uint256 value = exchangeTrx[_trxSeq].value;
        require(from != address(0),"trxSeq not exist");
        require(exchangeTrx[_trxSeq].executed == false,"trxSeq has executed");
        require(exchangeTrx[_trxSeq].signers.length >= requestSigners);
        require(from == msg.sender|| isSigner[msg.sender]);
        require(value <= balances[address(this)]);
        _burn(address(this), value);
        exchangeLock[from] = exchangeLock[from].sub(value);
        exchangeTrx[_trxSeq].executed = true;
        AbcInterface(AbcInstance).tokenFallback(from,value,bytes(""));
        emit TokenExchange(exchangeTrx[_trxSeq].from,exchangeTrx[_trxSeq].value,false);
    }

     
    function tokenFallback(address _from, uint _value, bytes memory) public {
        require(msg.sender == AbcInstance);
        require(_from != address(0));
        require(_value > 0);
        uint256 exchangeAmount = _value.mul(10**uint256(decimals)).div(10**uint256(AbcInterface(AbcInstance).decimals()));
        _mint(_from, exchangeAmount);
        emit Transfer(address(0x00),_from,exchangeAmount);
        emit TokenExchange(_from,_value,true);
    }

     
    function _mint(address target, uint256 value ) internal {
        balances[target] = balances[target].add(value);
        totalSupply = totalSupply.add(value);
        emit Mint(target,value);
    }
}