 

 
 
pragma solidity ^0.4.8;

contract Token {
     
     
    uint256 public totalSupply;

     
     
    function balanceOf(address _owner) constant returns (uint256 balance);

     
     
     
     
    function transfer(address _to, uint256 _value) returns (bool success);

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);

     
     
     
     
    function approve(address _spender, uint256 _value) returns (bool success);

     
     
     
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


contract StandardToken is Token {

    function transfer(address _to, uint256 _value) returns (bool success) {
         
         
         
        if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
         
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
}

contract UGToken is StandardToken {

    function () {
         
        throw;
    }

    string public name = "UG Token";                    
    uint8 public decimals = 18;                 
    string public symbol = "UGT";                  
    string public version = 'v0.1';        

    address public founder;  
    uint256 public allocateStartBlock;  
    uint256 public allocateEndBlock;  

     
    mapping(address => uint256) nonces;

    function UGToken() {
        founder = msg.sender;
        allocateStartBlock = block.number;
        allocateEndBlock = allocateStartBlock + 5082;  
    }

     
    function transferProxy(address _from, address _to, uint256 _value, uint256 _feeUgt,
        uint8 _v,bytes32 _r, bytes32 _s) returns (bool){

        if(balances[_from] < _feeUgt + _value) throw;

        uint256 nonce = nonces[_from];
        bytes32 h = sha3(_from,_to,_value,_feeUgt,nonce);
        if(_from != ecrecover(h,_v,_r,_s)) throw;

        if(balances[_to] + _value < balances[_to]
            || balances[msg.sender] + _feeUgt < balances[msg.sender]) throw;
        balances[_to] += _value;
        Transfer(_from, _to, _value);

        balances[msg.sender] += _feeUgt;
        Transfer(_from, msg.sender, _feeUgt);

        balances[_from] -= _value + _feeUgt;
        nonces[_from] = nonce + 1;
        return true;
    }

     
    function approveProxy(address _from, address _spender, uint256 _value,
        uint8 _v,bytes32 _r, bytes32 _s) returns (bool success) {

        uint256 nonce = nonces[_from];
        bytes32 hash = sha3(_from,_spender,_value,nonce);
        if(_from != ecrecover(hash,_v,_r,_s)) throw;
        allowed[_from][_spender] = _value;
        Approval(_from, _spender, _value);
        nonces[_from] = nonce + 1;
        return true;
    }


     
    function getNonce(address _addr) constant returns (uint256){
        return nonces[_addr];
    }

     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);

         
         
         
        if(!_spender.call(bytes4(bytes32(sha3("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData)) { throw; }
        return true;
    }

     
    function approveAndCallcode(address _spender, uint256 _value, bytes _extraData) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);

         
        if(!_spender.call(_extraData)) { throw; }
        return true;
    }

     
     
     
    function allocateTokens(address[] _owners, uint256[] _values) {

        if(msg.sender != founder) throw;
        if(block.number < allocateStartBlock || block.number > allocateEndBlock) throw;
        if(_owners.length != _values.length) throw;

        for(uint256 i = 0; i < _owners.length ; i++){
            address owner = _owners[i];
            uint256 value = _values[i];
            if(totalSupply + value <= totalSupply || balances[owner] + value <= balances[owner]) throw;
            totalSupply += value;
            balances[owner] += value;
        }
    }
}