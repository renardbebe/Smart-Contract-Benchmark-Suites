 

pragma solidity ^0.4.11;

 
 

 
contract Ownable {
    address public owner;

    function Ownable() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) {
            throw;
        }
        _;
    }
}
  
 
contract ERC223 {
    uint public totalSupply;
    function balanceOf(address who) constant returns (uint);
  
    function name() constant returns (string _name);
    function symbol() constant returns (string _symbol);
    function decimals() constant returns (uint8 _decimals);
    function totalSupply() constant returns (uint256 _supply);

    function transfer(address to, uint value) returns (bool ok);
    function transfer(address to, uint value, bytes data) returns (bool ok);
    event Transfer(address indexed from, address indexed to, uint value, bytes indexed data);
}

 
contract ContractReceiver {
    function tokenFallback(address _from, uint _value, bytes _data);
}

 
 
 
 
contract ERC223Token_STA is ERC223, SafeMath, Ownable {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    mapping(address => uint) balances;
    
     
    uint256 public icoEndBlock;                               
    uint256 public maxSupply;                                 
    uint256 public minedTokenCount;                           
    address public icoAddress;                                
    uint256 private multiplier;                               
    struct Miner {                                            
        uint256 block;
        address minerAddress;
    }
    mapping (uint256 => Miner) public minedTokens;            
    event MessageClaimMiningReward(address indexed miner, uint256 block, uint256 sta);   
    event Burn(address indexed from, uint256 value);          
    
    function ERC223Token_STA() {
        decimals = 8;
        multiplier = 10**uint256(decimals);
        maxSupply = 10000000000;                              
        name = "STABLE STA Token";                            
        symbol = "STA";                                       
        icoEndBlock = 4230150;   
        totalSupply = 0;                                      
         
    }
 
     
    function claimMiningReward() {  
        if (icoAddress == address(0)) throw;                          
        if (msg.sender != icoAddress && msg.sender != owner) throw;   
        if (block.number > icoEndBlock) throw;                        
        if (minedTokenCount * multiplier >= maxSupply) throw; 
        if (minedTokenCount > 0) {
            for (uint256 i = 0; i < minedTokenCount; i++) {
                if (minedTokens[i].block == block.number) throw; 
            }
        }
        totalSupply += 1 * multiplier;
        balances[block.coinbase] += 1 * multiplier;                   
        minedTokens[minedTokenCount] = Miner(block.number, block.coinbase);
        minedTokenCount += 1;
        MessageClaimMiningReward(block.coinbase, block.number, 1 * multiplier);
    } 
    
    function selfDestroy() onlyOwner {
        if (block.number <= icoEndBlock+14*3456) throw;            
        suicide(this); 
    }
     
   
     
    function name() constant returns (string _name) {
        return name;
    }
     
    function symbol() constant returns (string _symbol) {
        return symbol;
    }
     
    function decimals() constant returns (uint8 _decimals) {
        return decimals;
    }
     
    function totalSupply() constant returns (uint256 _totalSupply) {
        return totalSupply;
    }
    function minedTokenCount() constant returns (uint256 _minedTokenCount) {
        return minedTokenCount;
    }
    function icoAddress() constant returns (address _icoAddress) {
        return icoAddress;
    }

     
    function transfer(address _to, uint _value, bytes _data) returns (bool success) {
        if(isContract(_to)) {
            transferToContract(_to, _value, _data);
        }
        else {
            transferToAddress(_to, _value, _data);
        }
        return true;
    }
  
     
     
    function transfer(address _to, uint _value) returns (bool success) {
        bytes memory empty;
        if(isContract(_to)) {
            transferToContract(_to, _value, empty);
        }
        else {
            transferToAddress(_to, _value, empty);
        }
        return true;
    }

     
    function isContract(address _addr) private returns (bool is_contract) {
        uint length;
        _addr = _addr;   
        is_contract = is_contract;   
        assembly {
                 
                length := extcodesize(_addr)
        }
        if(length>0) {
            return true;
        }
        else {
            return false;
        }
    }

     
    function transferToAddress(address _to, uint _value, bytes _data) private returns (bool success) {
        if (balanceOf(msg.sender) < _value) throw;
        balances[msg.sender] = safeSub(balanceOf(msg.sender), _value);
        balances[_to] = safeAdd(balanceOf(_to), _value);
        Transfer(msg.sender, _to, _value, _data);
        return true;
    }
  
     
    function transferToContract(address _to, uint _value, bytes _data) private returns (bool success) {
        if (balanceOf(msg.sender) < _value) throw;
        balances[msg.sender] = safeSub(balanceOf(msg.sender), _value);
        balances[_to] = safeAdd(balanceOf(_to), _value);
        ContractReceiver receiver = ContractReceiver(_to);
        receiver.tokenFallback(msg.sender, _value, _data);
        Transfer(msg.sender, _to, _value, _data);
        return true;
    }

    function balanceOf(address _owner) constant returns (uint balance) {
        return balances[_owner];
    }
	
    function burn(address _address, uint256 _value) returns (bool success) {
        if (icoAddress == address(0)) throw;
        if (msg.sender != owner && msg.sender != icoAddress) throw;  
        if (balances[_address] < _value) throw;                      
        balances[_address] -= _value;                                
        totalSupply -= _value;                               
        Burn(_address, _value);
        return true;
    }
	
     
    function setIcoAddress(address _address) onlyOwner {
        if (icoAddress == address(0)) {
            icoAddress = _address;
        }    
        else throw;
    }
}

 
contract ERC223Token_STB is ERC223, SafeMath, Ownable {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    mapping(address => uint) balances;
    
     
    uint256 public maxSupply;
    uint256 public icoEndBlock;
    address public icoAddress;
	
    function ERC223Token_STB() {
        totalSupply = 0;                                      
        maxSupply = 1000000000000;                            
        name = "STABLE STB Token";                            
        decimals = 4;                                         
        symbol = "STB";                                       
        icoEndBlock = 4230150;   
         
    }
    
     
    function maxSupply() constant returns (uint256 _maxSupply) {
        return maxSupply;
    }
     
  
     
    function name() constant returns (string _name) {
        return name;
    }
     
    function symbol() constant returns (string _symbol) {
        return symbol;
    }
     
    function decimals() constant returns (uint8 _decimals) {
        return decimals;
    }
     
    function totalSupply() constant returns (uint256 _totalSupply) {
        return totalSupply;
    }
    function icoAddress() constant returns (address _icoAddress) {
        return icoAddress;
    }

     
    function transfer(address _to, uint _value, bytes _data) returns (bool success) {
        if(isContract(_to)) {
            transferToContract(_to, _value, _data);
        }
        else {
            transferToAddress(_to, _value, _data);
        }
        return true;
    }
  
     
     
    function transfer(address _to, uint _value) returns (bool success) {
        bytes memory empty;
        if(isContract(_to)) {
            transferToContract(_to, _value, empty);
        }
        else {
            transferToAddress(_to, _value, empty);
        }
        return true;
    }

     
    function isContract(address _addr) private returns (bool is_contract) {
        uint length;
        _addr = _addr;   
        is_contract = is_contract;   
        assembly {
             
            length := extcodesize(_addr)
        }
        if(length>0) {
            return true;
        }
        else {
            return false;
        }
    }

     
    function transferToAddress(address _to, uint _value, bytes _data) private returns (bool success) {
        if (balanceOf(msg.sender) < _value) throw;
        balances[msg.sender] = safeSub(balanceOf(msg.sender), _value);
        balances[_to] = safeAdd(balanceOf(_to), _value);
        Transfer(msg.sender, _to, _value, _data);
        return true;
    }
  
     
    function transferToContract(address _to, uint _value, bytes _data) private returns (bool success) {
        if (balanceOf(msg.sender) < _value) throw;
        balances[msg.sender] = safeSub(balanceOf(msg.sender), _value);
        balances[_to] = safeAdd(balanceOf(_to), _value);
        ContractReceiver receiver = ContractReceiver(_to);
        receiver.tokenFallback(msg.sender, _value, _data);
        Transfer(msg.sender, _to, _value, _data);
        return true;
    }

    function balanceOf(address _owner) constant returns (uint balance) {
        return balances[_owner];
    }

     
    function setIcoAddress(address _address) onlyOwner {
        if (icoAddress == address(0)) {
            icoAddress = _address;
        }    
        else throw;
    }

     
    function mint(address _receiver, uint256 _amount) {
        if (icoAddress == address(0)) throw;
        if (msg.sender != icoAddress && msg.sender != owner) throw;      
         
        if (safeAdd(totalSupply, _amount) > maxSupply) throw;
        totalSupply = safeAdd(totalSupply, _amount); 
        balances[_receiver] = safeAdd(balances[_receiver], _amount);
        Transfer(0, _receiver, _amount, new bytes(0)); 
    }
    
    function selfDestroy() onlyOwner {  
        suicide(this); 
    }
}

 
contract StableICO is Ownable, SafeMath {
    uint256 public crowdfundingTarget;          
    ERC223Token_STA public sta;                 
    ERC223Token_STB public stb;                 
    address public beneficiary;                 
    uint256 public icoStartBlock;               
    uint256 public icoEndBlock;                 
    bool public isIcoFinished;                  
    bool public isIcoSucceeded;                 
    bool public isDonatedEthTransferred;        
    bool public isStbMintedForStaEx;            
    uint256 public receivedStaAmount;           
    uint256 public totalFunded;                 
    uint256 public ownersEth;                   
    uint256 public oneStaIsStb;                 
    
    struct Donor {                                                       
        address donorAddress;
        uint256 ethAmount;
        uint256 block;
        bool exchangedOrRefunded;
        uint256 stbAmount;
    }
    mapping (uint256 => Donor) public donations;                         
    uint256 public donationNum;                                          
	
    struct Miner {                                                       
        address minerAddress;
        uint256 staAmount;
        uint256 block;
        bool exchanged;
        uint256 stbAmount;
    }
    mapping (uint256 => Miner) public receivedSta;                       
    uint256 public minerNum;                                             

     
    event Transfer(address indexed from, address indexed to, uint256 value); 
    
    event MessageExchangeEthStb(address from, uint256 eth, uint256 stb);
    event MessageExchangeStaStb(address from, uint256 sta, uint256 stb);
    event MessageReceiveEth(address from, uint256 eth, uint256 block);
    event MessageReceiveSta(address from, uint256 sta, uint256 block);
    event MessageReceiveStb(address from, uint256 stb, uint256 block, bytes data);   
    event MessageRefundEth(address donor_address, uint256 eth);
  
     
    function StableICO() {
        crowdfundingTarget = 200000000000000000;  
        sta = ERC223Token_STA(0xe1e8f9bd535384a345c2a7a29a15df8fc345ad9c);   
        stb = ERC223Token_STB(0x1e46a3f0552c5acf8ced4fe21a789b412f0e792a);   
        beneficiary = 0x29ef9329bc15b7c11d047217618186b52bb4c8ff;   
        icoStartBlock = 4230000;   
        icoEndBlock = 4230150;   
    }		
    
     
    function claimMiningReward() public onlyOwner {
        sta.claimMiningReward();
    }
	
     
    function tokenFallback(address _from, uint256 _value, bytes _data) {
        if (block.number < icoStartBlock) throw;
        if (msg.sender == address(sta)) {
            if (_value < 50000000) throw;  
            if (block.number < icoEndBlock+14*3456) {   
                receivedSta[minerNum] = Miner(_from, _value, block.number, false, 0);
                minerNum += 1;
                receivedStaAmount = safeAdd(receivedStaAmount, _value);
                MessageReceiveSta(_from, _value, block.number);
            } else throw;	
        } else if(msg.sender == address(stb)) {
            MessageReceiveStb(_from, _value, block.number, _data);
        } else {
            throw;  
        }
    }

     
    function () payable {

        if (msg.value < 10000000000000000) throw;   
		
         
        if (block.number < icoStartBlock) {
            if (msg.sender == owner) {
                ownersEth = safeAdd(ownersEth, msg.value);
            } else {
                totalFunded = safeAdd(totalFunded, msg.value);
                donations[donationNum] = Donor(msg.sender, msg.value, block.number, false, 0);
                donationNum += 1;
                MessageReceiveEth(msg.sender, msg.value, block.number);
            }    
        } 
         
        else if (block.number >= icoStartBlock && block.number <= icoEndBlock) {
            if (msg.sender != owner) {
                totalFunded = safeAdd(totalFunded, msg.value);
                donations[donationNum] = Donor(msg.sender, msg.value, block.number, false, 0);
                donationNum += 1;
                MessageReceiveEth(msg.sender, msg.value, block.number);
            } else ownersEth = safeAdd(ownersEth, msg.value);
        }
         
        else if (block.number > icoEndBlock) {
            if (!isIcoFinished) {
                isIcoFinished = true;
                msg.sender.transfer(msg.value);   
                if (totalFunded >= crowdfundingTarget) {
                    isIcoSucceeded = true;
                    exchangeStaStb(0, minerNum);
                    exchangeEthStb(0, donationNum);
                    drawdown();
                } else {
                    refund(0, donationNum);
                }	
            } else {
                if (msg.sender != owner) throw;   
                ownersEth = safeAdd(ownersEth, msg.value);
            }    
        } else {
            throw;   
        }
    }

     
    function exchangeStaStb(uint256 _from, uint256 _to) private {  
        if (!isIcoSucceeded) throw;
        if (_from >= _to) return;   
        uint256 _sta2stb = 10**4; 
        uint256 _wei2stb = 10**14; 

        if (!isStbMintedForStaEx) {
            uint256 _mintAmount = (10*totalFunded)*5/1000 / _wei2stb;   
            oneStaIsStb = _mintAmount / 100;
            stb.mint(address(this), _mintAmount);
            isStbMintedForStaEx = true;
        }	
			
         
        uint256 _toBurn = 0;
        for (uint256 i = _from; i < _to; i++) {
            if (receivedSta[i].exchanged) continue;   
            stb.transfer(receivedSta[i].minerAddress, receivedSta[i].staAmount/_sta2stb * oneStaIsStb / 10**4);
            receivedSta[i].exchanged = true;
            receivedSta[i].stbAmount = receivedSta[i].staAmount/_sta2stb * oneStaIsStb / 10**4;
            _toBurn += receivedSta[i].staAmount;
            MessageExchangeStaStb(receivedSta[i].minerAddress, receivedSta[i].staAmount, 
              receivedSta[i].staAmount/_sta2stb * oneStaIsStb / 10**4);
        }
        sta.burn(address(this), _toBurn);   
    }
	
     
    function exchangeEthStb(uint256 _from, uint256 _to) private { 
        if (!isIcoSucceeded) throw;
        if (_from >= _to) return;   
        uint256 _wei2stb = 10**14;  
        uint _pb = (icoEndBlock - icoStartBlock)/4; 
        uint _bonus;

         
        uint256 _mintAmount = 0;
        for (uint256 i = _from; i < _to; i++) {
            if (donations[i].exchangedOrRefunded) continue;   
            if (donations[i].block < icoStartBlock + _pb) _bonus = 6;   
            else if (donations[i].block >= icoStartBlock + _pb && donations[i].block < icoStartBlock + 2*_pb) _bonus = 4;   
            else if (donations[i].block >= icoStartBlock + 2*_pb && donations[i].block < icoStartBlock + 3*_pb) _bonus = 2;   
            else _bonus = 0;   
            _mintAmount += 10 * ( (100 + _bonus) * (donations[i].ethAmount / _wei2stb) / 100);
        }
        stb.mint(address(this), _mintAmount);

         
        for (i = _from; i < _to; i++) {
            if (donations[i].exchangedOrRefunded) continue;   
            if (donations[i].block < icoStartBlock + _pb) _bonus = 6;   
            else if (donations[i].block >= icoStartBlock + _pb && donations[i].block < icoStartBlock + 2*_pb) _bonus = 4;   
            else if (donations[i].block >= icoStartBlock + 2*_pb && donations[i].block < icoStartBlock + 3*_pb) _bonus = 2;   
            else _bonus = 0;   
            stb.transfer(donations[i].donorAddress, 10 * ( (100 + _bonus) * (donations[i].ethAmount / _wei2stb) / 100) );
            donations[i].exchangedOrRefunded = true;
            donations[i].stbAmount = 10 * ( (100 + _bonus) * (donations[i].ethAmount / _wei2stb) / 100);
            MessageExchangeEthStb(donations[i].donorAddress, donations[i].ethAmount, 
              10 * ( (100 + _bonus) * (donations[i].ethAmount / _wei2stb) / 100));
        }
    }
  
     
    function drawdown() private {
        if (!isIcoSucceeded || isDonatedEthTransferred) throw;
        beneficiary.transfer(totalFunded);  
        isDonatedEthTransferred = true;
    }
  
     
    function refund(uint256 _from, uint256 _to) private {
        if (!isIcoFinished || isIcoSucceeded) throw;
        if (_from >= _to) return;
        for (uint256 i = _from; i < _to; i++) {
            if (donations[i].exchangedOrRefunded) continue;
            donations[i].donorAddress.transfer(donations[i].ethAmount);
            donations[i].exchangedOrRefunded = true;
            MessageRefundEth(donations[i].donorAddress, donations[i].ethAmount);
        }
    }
    
     
    function transferEthToOwner(uint256 _amount) public onlyOwner { 
        if (!isIcoFinished || _amount <= 0 || _amount > ownersEth) throw;
        owner.transfer(_amount); 
        ownersEth -= _amount;
    }    

     
    function transferStbToOwner(uint256 _amount) public onlyOwner { 
        if (!isIcoFinished || _amount <= 0) throw;
        stb.transfer(owner, _amount); 
    }    
    
    
     
    function backup_finishIcoVars() public onlyOwner {
        if (block.number <= icoEndBlock || isIcoFinished) throw;
        isIcoFinished = true;
        if (totalFunded >= crowdfundingTarget) isIcoSucceeded = true;
    }
    function backup_exchangeStaStb(uint256 _from, uint256 _to) public onlyOwner { 
        exchangeStaStb(_from, _to);
    }
    function backup_exchangeEthStb(uint256 _from, uint256 _to) public onlyOwner { 
        exchangeEthStb(_from, _to);
    }
    function backup_drawdown() public onlyOwner { 
        drawdown();
    }
    function backup_drawdown_amount(uint256 _amount) public onlyOwner {
        if (!isIcoSucceeded) throw;
        beneficiary.transfer(_amount);  
    }
    function backup_refund(uint256 _from, uint256 _to) public onlyOwner { 
        refund(_from, _to);
    }
     

    function selfDestroy() onlyOwner {  
        suicide(this); 
    }
}