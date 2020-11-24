 

pragma solidity ^0.4.9;

  
 
contract ContractReceiver {
    function tokenFallback(address _from, uint _value, bytes _data) public;
} 

  
 
 
  
    function CoinvestToken(uint256 _lockupEndTime)
      public
    {
        balances[msg.sender] = totalSupply;
        lockupEndTime = _lockupEndTime;
        maintainer = msg.sender;
    }
  
  
     
    function transfer(address _to, uint _value, bytes _data, string _custom_fallback) transferable returns (bool success) {
      
        if(isContract(_to)) {
            if (balanceOf(msg.sender) < _value) throw;
            balances[msg.sender] = safeSub(balanceOf(msg.sender), _value);
            balances[_to] = safeAdd(balanceOf(_to), _value);
            assert(_to.call.value(0)(bytes4(sha3(_custom_fallback)), msg.sender, _value, _data));
            if(Transfer_data_enabled)
            {
                Transfer(msg.sender, _to, _value, _data);
            }
            if(Transfer_nodata_enabled)
            {
                Transfer(msg.sender, _to, _value);
            }
            if(ERC223Transfer_enabled)
            {
                ERC223Transfer(msg.sender, _to, _value, _data);
            }
            return true;
        }
        else {
            return transferToAddress(_to, _value, _data);
        }
    }

    function ERC20transfer(address _to, uint _value, bytes _data) transferable returns (bool success) {
        bytes memory empty;
        return transferToAddress(_to, _value, empty);
    }

     
    function transfer(address _to, uint _value, bytes _data) transferable returns (bool success) {
        if(isContract(_to)) {
            return transferToContract(_to, _value, _data);
        }
        else {
            return transferToAddress(_to, _value, _data);
        }
    }
  
     
     
    function transfer(address _to, uint _value) transferable returns (bool success) {
      
         
         
        bytes memory empty;
        if(isContract(_to)) {
            return transferToContract(_to, _value, empty);
        }
        else {
            return transferToAddress(_to, _value, empty);
        }
    }

     
    function isContract(address _addr) public returns (bool is_contract) {
        uint length;
        assembly {
             
            length := extcodesize(_addr)
        }
        return (length>0);
    }

     
    function transferToAddress(address _to, uint _value, bytes _data) private returns (bool success) {
        if (balanceOf(msg.sender) < _value) throw;
        balances[msg.sender] = safeSub(balanceOf(msg.sender), _value);
        balances[_to] = safeAdd(balanceOf(_to), _value);
        if(Transfer_data_enabled)
        {
            Transfer(msg.sender, _to, _value, _data);
        }
        if(Transfer_nodata_enabled)
        {
            Transfer(msg.sender, _to, _value);
        }
        if(ERC223Transfer_enabled)
        {
            ERC223Transfer(msg.sender, _to, _value, _data);
        }
        return true;
    }
  
     
    function transferToContract(address _to, uint _value, bytes _data) private returns (bool success) {
        if (balanceOf(msg.sender) < _value) throw;
        balances[msg.sender] = safeSub(balanceOf(msg.sender), _value);
        balances[_to] = safeAdd(balanceOf(_to), _value);
        ContractReceiver receiver = ContractReceiver(_to);
        receiver.tokenFallback(msg.sender, _value, _data);
        if(Transfer_data_enabled)
        {
            Transfer(msg.sender, _to, _value, _data);
        }
        if(Transfer_nodata_enabled)
        {
            Transfer(msg.sender, _to, _value);
        }
        if(ERC223Transfer_enabled)
        {
            ERC223Transfer(msg.sender, _to, _value, _data);
        }
        return true;
    }


    function balanceOf(address _owner) constant returns (uint balance) {
        return balances[_owner];
    }
    
    function totalSupply() constant returns (uint256) {
        return totalSupply;
    }

     
    function transferFrom(address _from, address _to, uint _amount)
      external
      transferable
    returns (bool success)
    {
        require(balances[_from] >= _amount && allowed[_from][msg.sender] >= _amount);

        allowed[_from][msg.sender] -= _amount;
        balances[_from] -= _amount;
        balances[_to] += _amount;
        bytes memory empty;
        
        Transfer(_from, _to, _amount, empty);
        return true;
    }

     
    function approve(address _spender, uint256 _amount) 
      external
      transferable  
    {
        require(balances[msg.sender] >= _amount);
        
        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
    }
    
     
    function token_escape(address _tokenContract)
      external
      only_maintainer
    {
        CoinvestToken lostToken = CoinvestToken(_tokenContract);
        
        uint256 stuckTokens = lostToken.balanceOf(address(this));
        lostToken.transfer(maintainer, stuckTokens);
    }

     
    function setIcoContract(address _icoContract)
      external
      only_maintainer
    {
        require(icoContract == 0);
        icoContract = _icoContract;
    }

     
    function allowance(address _owner, address _spender) 
      external
      constant 
    returns (uint256) 
    {
        return allowed[_owner][_spender];
    }
    
    function adjust_ERC223Transfer(bool _value) only_maintainer
    {
        ERC223Transfer_enabled = _value;
    }
    
    function adjust_Transfer_nodata(bool _value) only_maintainer
    {
        Transfer_nodata_enabled = _value;
    }
    
    function adjust_Transfer_data(bool _value) only_maintainer
    {
        Transfer_data_enabled = _value;
    }
    
    modifier only_maintainer
    {
        assert(msg.sender == maintainer);
        _;
    }
    
     
    function transferMaintainer(address newMaintainer) only_maintainer public {
        require(newMaintainer != address(0));
        maintainer = newMaintainer;
    }
    
    modifier transferable
    {
        if (block.timestamp < lockupEndTime) {
            require(msg.sender == maintainer || msg.sender == icoContract);
        }
        _;
    }
    
}