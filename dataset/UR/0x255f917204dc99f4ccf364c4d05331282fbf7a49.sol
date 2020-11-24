 

pragma solidity ^0.4.15;


 

library ECRecovery {

   
  function recover(bytes32 hash, bytes sig) public constant returns (address) {
    bytes32 r;
    bytes32 s;
    uint8 v;

     
    if (sig.length != 65) {
      return (address(0));
    }

     
    assembly {
      r := mload(add(sig, 32))
      s := mload(add(sig, 64))
      v := byte(0, mload(add(sig, 96)))
    }

     
    if (v < 27) {
      v += 27;
    }

     
    if (v != 27 && v != 28) {
      return (address(0));
    } else {
      return ecrecover(hash, v, r, s);
    }
  }

}


 
 
library ChannelLibrary {
    
    struct Data {
        uint close_timeout;
        uint settle_timeout;
        uint audit_timeout;
        uint opened;
        uint close_requested;
        uint closed;
        uint settled;
        uint audited;
        ChannelManagerContract manager;
    
        address sender;
        address receiver;
        address client;
        uint balance;
        address auditor;

         
        uint nonce;
        uint completed_transfers;
    }

    struct StateUpdate {
        uint nonce;
        uint completed_transfers;
    }

    modifier notSettledButClosed(Data storage self) {
        require(self.settled <= 0 && self.closed > 0);
        _;
    }

    modifier notAuditedButClosed(Data storage self) {
        require(self.audited <= 0 && self.closed > 0);
        _;
    }

    modifier stillTimeout(Data storage self) {
        require(self.closed + self.settle_timeout >= block.number);
        _;
    }

    modifier timeoutOver(Data storage self) {
        require(self.closed + self.settle_timeout <= block.number);
        _;
    }

    modifier channelSettled(Data storage self) {
        require(self.settled != 0);
        _;
    }

    modifier senderOnly(Data storage self) {
        require(self.sender == msg.sender);
        _;
    }

    modifier receiverOnly(Data storage self) {
        require(self.receiver == msg.sender);
        _;
    }

     
     
     
     
     
    function deposit(Data storage self, uint256 amount) 
    senderOnly(self)
    returns (bool success, uint256 balance)
    {
        require(self.opened > 0);
        require(self.closed == 0);

        StandardToken token = self.manager.token();

        require (token.balanceOf(msg.sender) >= amount);

        success = token.transferFrom(msg.sender, this, amount);
    
        if (success == true) {
            self.balance += amount;

            return (true, self.balance);
        }

        return (false, 0);
    }

    function request_close(
        Data storage self
    ) {
        require(msg.sender == self.sender || msg.sender == self.receiver);
        require(self.close_requested == 0);
        self.close_requested = block.number;
    }

    function close(
        Data storage self,
        address channel_address,
        uint nonce,
        uint completed_transfers,
        bytes signature
    )
    {
        if (self.close_timeout > 0) {
            require(self.close_requested > 0);
            require(block.number - self.close_requested >= self.close_timeout);
        }
        require(nonce > self.nonce);
        require(completed_transfers >= self.completed_transfers);
        require(completed_transfers <= self.balance);
    
        if (msg.sender != self.sender) {
             
            bytes32 signed_hash = hashState(
                channel_address,
                nonce,
                completed_transfers
            );

            address sign_address = ECRecovery.recover(signed_hash, signature);
            require(sign_address == self.sender);
        }

        if (self.closed == 0) {
            self.closed = block.number;
        }
    
        self.nonce = nonce;
        self.completed_transfers = completed_transfers;
    }

    function hashState (
        address channel_address,
        uint nonce,
        uint completed_transfers
    ) returns (bytes32) {
        return sha3 (
            channel_address,
            nonce,
            completed_transfers
        );
    }

     
     
     
    function settle(Data storage self)
        notSettledButClosed(self)
        timeoutOver(self)
    {
        StandardToken token = self.manager.token();
        
        if (self.completed_transfers > 0) {
            require(token.transfer(self.receiver, self.completed_transfers));
        }

        if (self.completed_transfers < self.balance) {
            require(token.transfer(self.sender, self.balance - self.completed_transfers));
        }

        self.settled = block.number;
    }

    function audit(Data storage self, address auditor)
        notAuditedButClosed(self) {
        require(self.auditor == auditor);
        require(block.number <= self.closed + self.audit_timeout);
        self.audited = block.number;
    }

    function validateTransfer(
        Data storage self,
        address transfer_id,
        address channel_address,
        uint sum,
        bytes lock_data,
        bytes signature
    ) returns (uint256) {

        bytes32 signed_hash = hashTransfer(
            transfer_id,
            channel_address,
            lock_data,
            sum
        );

        address sign_address = ECRecovery.recover(signed_hash, signature);
        require(sign_address == self.client);
    }

    function hashTransfer(
        address transfer_id,
        address channel_address,
        bytes lock_data,
        uint sum
    ) returns (bytes32) {
        if (lock_data.length > 0) {
            return sha3 (
                transfer_id,
                channel_address,
                sum,
                lock_data
            );
        } else {
            return sha3 (
                transfer_id,
                channel_address,
                sum
            );
        }
    }
}


 
 
contract ERC20 {

   

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);

   

  function transfer(address _to, uint256 _value) public returns (bool);
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool);
  function approve(address _spender, uint256 _value) public returns (bool);
  function balanceOf(address _owner) public constant returns (uint256);
  function allowance(address _owner, address _spender) public constant returns (uint256);

   

  uint256 public totalSupply;
}


 
 
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}


 
 
contract StandardToken is ERC20 {
  using SafeMath for uint256;

   

   
   
   
   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }
  
   
   
   
   
   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowances[_from][msg.sender]);
    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowances[_from][msg.sender] = allowances[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
   
   
   
   
   
   
   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowances[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
   
   
  function balanceOf(address _owner) public constant returns (uint256) {
    return balances[_owner];
  }

   
   
   
   
  function allowance(address _owner, address _spender) public constant returns (uint256) {
    return allowances[_owner][_spender];
  }

   

  mapping (address => uint256) balances;
  mapping (address => mapping (address => uint256)) allowances;
}


contract ChannelApi {
    function applyRuntimeUpdate(address from, address to, uint impressionsCount, uint fraudCount);

    function applyAuditorsCheckUpdate(address from, address to, uint fraudCountDelta);
}


contract ChannelContract {
    using ChannelLibrary for ChannelLibrary.Data;
    ChannelLibrary.Data data;

    event ChannelNewBalance(address token_address, address participant, uint balance, uint block_number);
    event ChannelCloseRequested(address closing_address, uint block_number);
    event ChannelClosed(address closing_address, uint block_number);
    event TransferUpdated(address node_address, uint block_number);
    event ChannelSettled(uint block_number);
    event ChannelAudited(uint block_number);
    event ChannelSecretRevealed(bytes32 secret, address receiver_address);

    modifier onlyManager() {
        require(msg.sender == address(data.manager));
        _;
    }

    function ChannelContract(
        address manager_address,
        address sender,
        address client,
        address receiver,
        uint close_timeout,
        uint settle_timeout,
        uint audit_timeout,
        address auditor
    )
    {
         
        require(msg.sender == manager_address);
        require (sender != receiver);
        require (client != receiver);
        require (audit_timeout >= 0);
        require (settle_timeout > 0);
        require (close_timeout >= 0);

        data.sender = sender;
        data.client = client;
        data.receiver = receiver;
        data.auditor = auditor;
        data.manager = ChannelManagerContract(manager_address);
        data.close_timeout = close_timeout;
        data.settle_timeout = settle_timeout;
        data.audit_timeout = audit_timeout;
        data.opened = block.number;
    }

     
     
     
    function deposit(uint256 amount) returns (bool) {
        bool success;
        uint256 balance;

        (success, balance) = data.deposit(amount);

        if (success == true) {
            ChannelNewBalance(data.manager.token(), msg.sender, balance, 0);
        }

        return success;
    }

     
     
    function addressAndBalance()
        constant
        returns (
        address sender,
        address receiver,
        uint balance)
    {
        sender = data.sender;
        receiver = data.receiver;
        balance = data.balance;
    }

     
    function request_close () {
        data.request_close();
        ChannelCloseRequested(msg.sender, data.closed);
    }

     
    function close (
        uint nonce,
        uint256 completed_transfers,
        bytes signature
    ) {
        data.close(address(this), nonce, completed_transfers, signature);
        ChannelClosed(msg.sender, data.closed);
    }

     
     
     
     
    function settle() {
        data.settle();
        ChannelSettled(data.settled);
    }

     
     
     
     
    function audit(address auditor) onlyManager {
        data.audit(auditor);
        ChannelAudited(data.audited);
    }

    function destroy() onlyManager {
        require(data.settled > 0);
        require(data.audited > 0 || block.number > data.closed + data.audit_timeout);
        selfdestruct(0);
    }

    function sender() constant returns (address) {
        return data.sender;
    }

    function receiver() constant returns (address) {
        return data.receiver;
    }

    function client() constant returns (address) {
        return data.client;
    }

    function auditor() constant returns (address) {
        return data.auditor;
    }

    function closeTimeout() constant returns (uint) {
        return data.close_timeout;
    }

    function settleTimeout() constant returns (uint) {
        return data.settle_timeout;
    }

    function auditTimeout() constant returns (uint) {
        return data.audit_timeout;
    }

     
    function manager() constant returns (address) {
        return data.manager;
    }

    function balance() constant returns (uint) {
        return data.balance;
    }

    function nonce() constant returns (uint) {
        return data.nonce;
    }

    function completedTransfers() constant returns (uint) {
        return data.completed_transfers;
    }

     
     
    function opened() constant returns (uint) {
        return data.opened;
    }

    function closeRequested() constant returns (uint) {
        return data.close_requested;
    }

    function closed() constant returns (uint) {
        return data.closed;
    }

    function settled() constant returns (uint) {
        return data.settled;
    }

    function audited() constant returns (uint) {
        return data.audited;
    }

    function () { revert(); }
}


contract ChannelManagerContract {

    event ChannelNew(
        address channel_address,
        address indexed sender,
        address client,
        address indexed receiver,
        uint close_timeout,
        uint settle_timeout,
        uint audit_timeout
    );

    event ChannelDeleted(
        address channel_address,
        address indexed sender,
        address indexed receiver
    );

    StandardToken public token;
    ChannelApi public channel_api;

    function ChannelManagerContract(address token_address, address channel_api_address) {
        require(token_address != 0);
        require(channel_api_address != 0);
        token = StandardToken(token_address);
        channel_api = ChannelApi(channel_api_address);
    }

     
     
     
     
    function newChannel(
        address client, 
        address receiver, 
        uint close_timeout,
        uint settle_timeout,
        uint audit_timeout,
        address auditor
    )
        returns (address)
    {
        address new_channel_address = new ChannelContract(
            this,
            msg.sender,
            client,
            receiver,
            close_timeout,
            settle_timeout,
            audit_timeout,
            auditor
        );

        ChannelNew(
            new_channel_address, 
            msg.sender, 
            client, 
            receiver,
            close_timeout,
            settle_timeout,
            audit_timeout
        );

        return new_channel_address;
    }

    function auditReport(address contract_address, uint total, uint fraud) {
        ChannelContract ch = ChannelContract(contract_address);
        require(ch.manager() == address(this));
        address auditor = msg.sender;
        ch.audit(auditor);
        channel_api.applyRuntimeUpdate(ch.sender(), ch.receiver(), total, fraud);
    }
    
    function destroyChannel(address channel_address) {
        ChannelContract ch = ChannelContract(channel_address);
        require(ch.manager() == address(this));
        ChannelDeleted(channel_address,ch.sender(),ch.receiver());
        ch.destroy();
    }
}