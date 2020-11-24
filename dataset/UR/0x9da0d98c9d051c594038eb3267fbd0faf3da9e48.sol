 

pragma solidity ^0.4.24;

 

  

contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) constant returns (uint256);
    function transfer(address to, uint256 value) returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}


 
contract JeiCoinToken {

     
    string public name;
    string public symbol;
    uint8 public decimals; 
    string public version = 'v1.5';
    uint256 public totalSupply;
    uint public price;
    bool public locked;
    uint multiplier;

    address public rootAddress;
    address public Owner;

    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowed;
    mapping(address => bool) public freezed;

    mapping(address => uint) public maxIndex;  
    mapping(address => uint) public minIndex;  
    mapping(address => mapping(uint => Batch)) public batches;  

    struct Batch {
        uint quant;
        uint age;
    }

     
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);


     

    modifier onlyOwner() {
        if ( msg.sender != rootAddress && msg.sender != Owner ) revert();
        _;
    }

    modifier onlyRoot() {
        if ( msg.sender != rootAddress ) revert();
        _;
    }

    modifier isUnlocked() {
    	if ( locked && msg.sender != rootAddress && msg.sender != Owner ) revert();
		_;    	
    }

    modifier isUnfreezed(address _to) {
    	if ( freezed[msg.sender] || freezed[_to] ) revert();
    	_;
    }

     
    function safeSub(uint x, uint y) pure internal returns (uint z) {
        require((z = x - y) <= x);
    }


     
    constructor(address _root) {        
        locked = false;
        name = 'JeiCoin Gold'; 
        symbol = 'JEIG'; 
        decimals = 18; 
        multiplier = 10 ** uint(decimals);
        totalSupply = 63000000 * multiplier;  
        if (_root != 0x0) rootAddress = _root; else rootAddress = msg.sender;  
        Owner = msg.sender;

         
        balances[rootAddress] = totalSupply; 
        batches[rootAddress][0].quant = totalSupply;
        batches[rootAddress][0].age = now;
        maxIndex[rootAddress] = 1;
    }


     

    function changeRoot(address _newRootAddress) onlyRoot returns(bool){
        rootAddress = _newRootAddress;
        return true;
    }

     

     
    function sendToken(address _token,address _to , uint _value) onlyOwner returns(bool) {
        ERC20Basic Token = ERC20Basic(_token);
        require(Token.transfer(_to, _value));
        return true;
    }

    function changeOwner(address _newOwner) onlyOwner returns(bool) {
        Owner = _newOwner;
        return true;
    }
       
    function unlock() onlyOwner returns(bool) {
        locked = false;
        return true;
    }

    function lock() onlyOwner returns(bool) {
        locked = true;
        return true;
    }

    function freeze(address _address) onlyOwner returns(bool) {
        freezed[_address] = true;
        return true;
    }

    function unfreeze(address _address) onlyOwner returns(bool) {
        freezed[_address] = false;
        return true;
    }

    function burn(uint256 _value) onlyOwner returns(bool) {
        require (balances[msg.sender] >= _value);
        balances[msg.sender] = balances[msg.sender] - _value;
        totalSupply = safeSub( totalSupply,  _value );
        emit Transfer(msg.sender, 0x0,_value);
        return true;
    }

     
     
    function transfer(address _to, uint _value) isUnlocked public returns (bool success) {
        require(msg.sender != _to);
        if (balances[msg.sender] < _value) return false;
        if (freezed[msg.sender] || freezed[_to]) return false;  
        balances[msg.sender] = balances[msg.sender] - _value;
        balances[_to] = balances[_to] + _value;

        updateBatches(msg.sender, _to, _value);

        emit Transfer(msg.sender,_to,_value);
        return true;
        }


    function transferFrom(address _from, address _to, uint256 _value) isUnlocked public returns(bool) {
        require(_from != _to);
        if ( freezed[_from] || freezed[_to] ) return false;  
        if ( balances[_from] < _value ) return false;  
    	if ( _value > allowed[_from][msg.sender] ) return false;  

        balances[_from] = balances[_from] - _value;  
        balances[_to] = balances[_to] + _value;  

        allowed[_from][msg.sender] = allowed[_from][msg.sender] - _value;

        updateBatches(_from, _to, _value);

        emit Transfer(_from,_to,_value);
        return true;
    }

    function approve(address _spender, uint _value) public returns(bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }


     

    function isLocked() public view returns(bool) {
        return locked;
    }

    function balanceOf(address _owner) public view returns(uint256 balance) {
        return balances[_owner];
    }

    function allowance(address _owner, address _spender) public view returns(uint256) {
        return allowed[_owner][_spender];
    }


     

    function getBatch(address _address , uint _batch) public view returns(uint _quant,uint _age) {
        return (batches[_address][_batch].quant , batches[_address][_batch].age);
    }

    function getFirstBatch(address _address) public view returns(uint _quant,uint _age) {
        return (batches[_address][minIndex[_address]].quant , batches[_address][minIndex[_address]].age);
    }

     
    function updateBatches(address _from,address _to,uint _value) private {
         
        uint count = _value;
        uint i = minIndex[_from];
         while(count > 0) {  
            uint _quant = batches[_from][i].quant;
            if ( count >= _quant ) {  
                 
                count -= _quant;  
                batches[_from][i].quant = 0;  
                minIndex[_from] = i + 1;
                } else {  
                     
                    batches[_from][i].quant -= count;  
                    count = 0;  
                    }
            i++;
        }  

         
         
        Batch memory thisBatch;
        thisBatch.quant = _value;
        thisBatch.age = now;
         
        batches[_to][maxIndex[_to]] = thisBatch;
        maxIndex[_to]++;
    }

}