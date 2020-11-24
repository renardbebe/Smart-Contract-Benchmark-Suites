 

pragma solidity ^0.4.18;

 
contract Controlled {
  address public controller;

  function Controlled() public {
    controller = msg.sender;
  }

  modifier onlyController {
    require(msg.sender == controller);
    _;
  }

  function transferControl(address newController) public onlyController{
    controller = newController;
  }
} 





 
 
 
 
 
 
 


 

contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 _amount, address _token, bytes _data) public;
}

 
 
 
contract MiniMeToken is Controlled {

    string public name;                 
    uint8 public decimals;              
    string public symbol;               


     
     
     
    struct  Checkpoint {

         
        uint128 fromBlock;

         
        uint128 value;
    }

     
     
    MiniMeToken public parentToken;

     
     
    uint public parentSnapShotBlock;

     
    uint public creationBlock;

     
     
     
    mapping (address => Checkpoint[]) balances;

     
    mapping (address => mapping (address => uint256)) allowed;

     
    Checkpoint[] totalSupplyHistory;

     
    bool public transfersEnabled;

     
    MiniMeTokenFactory public tokenFactory;

 
 
 

     
     
     
     
     
     
     
     
     
     
     
     
     
    function MiniMeToken(
        address _tokenFactory,
        address _parentToken,
        uint _parentSnapShotBlock,
        string _tokenName,
        uint8 _decimalUnits,
        string _tokenSymbol,
        bool _transfersEnabled
    ) public {
        tokenFactory = MiniMeTokenFactory(_tokenFactory);
        name = _tokenName;                                  
        decimals = _decimalUnits;                           
        symbol = _tokenSymbol;                              
        parentToken = MiniMeToken(_parentToken);
        parentSnapShotBlock = _parentSnapShotBlock;
        transfersEnabled = _transfersEnabled;
        creationBlock = block.number;
    }


 
 
 

     
     
     
     
    function transfer(address _to, uint256 _amount) public returns (bool success) {
        require(transfersEnabled);
        return doTransfer(msg.sender, _to, _amount);
    }

     
     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _amount
    ) public returns (bool success) {

         
         
         
         
        if (msg.sender != controller) {
            require(transfersEnabled);

             
            if (allowed[_from][msg.sender] < _amount) return false;
            allowed[_from][msg.sender] -= _amount;
        }
        return doTransfer(_from, _to, _amount);
    }

     
     
     
     
     
     
    function doTransfer(address _from, address _to, uint _amount
    ) internal returns(bool) {

           if (_amount == 0) {
               return true;
           }

           require(parentSnapShotBlock < block.number);

            
           require((_to != address(0x0)) && (_to != address(this)));

            
            
           var previousBalanceFrom = balanceOfAt(_from, block.number);
           if (previousBalanceFrom < _amount) {
               return false;
           }

            
            
                
            

            
            
           updateValueAtNow(balances[_from], previousBalanceFrom - _amount);

            
            
           var previousBalanceTo = balanceOfAt(_to, block.number);
           require(previousBalanceTo + _amount >= previousBalanceTo);  
           updateValueAtNow(balances[_to], previousBalanceTo + _amount);

            
           Transfer(_from, _to, _amount);

           return true;
    }

     
     
    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balanceOfAt(_owner, block.number);
    }

     
     
     
     
     
     
    function approve(address _spender, uint256 _amount) public returns (bool success) {
        require(transfersEnabled);

         
         
         
         
        require((_amount == 0) || (allowed[msg.sender][_spender] == 0));

         
         
             
         

        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }

     
     
     
     
     
    function allowance(address _owner, address _spender
    ) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

     
     
     
     
     
     
     
    function approveAndCall(address _spender, uint256 _amount, bytes _extraData
    ) public returns (bool success) {
        require(approve(_spender, _amount));

        ApproveAndCallFallBack(_spender).receiveApproval(
            msg.sender,
            _amount,
            this,
            _extraData
        );

        return true;
    }

     
     
    function totalSupply() public constant returns (uint) {
        return totalSupplyAt(block.number);
    }


 
 
 

     
     
     
     
    function balanceOfAt(address _owner, uint _blockNumber) public constant
        returns (uint) {

         
         
         
         
         
        if ((balances[_owner].length == 0)
            || (balances[_owner][0].fromBlock > _blockNumber)) {
            if (address(parentToken) != 0) {
                return parentToken.balanceOfAt(_owner, min(_blockNumber, parentSnapShotBlock));
            } else {
                 
                return 0;
            }

         
        } else {
            return getValueAt(balances[_owner], _blockNumber);
        }
    }

     
     
     
    function totalSupplyAt(uint _blockNumber) public constant returns(uint) {

         
         
         
         
         
        if ((totalSupplyHistory.length == 0)
            || (totalSupplyHistory[0].fromBlock > _blockNumber)) {
            if (address(parentToken) != 0) {
                return parentToken.totalSupplyAt(min(_blockNumber, parentSnapShotBlock));
            } else {
                return 0;
            }

         
        } else {
            return getValueAt(totalSupplyHistory, _blockNumber);
        }
    }

 
 
 

     
     
     
     
     
     
     
     
     
     
    function createCloneToken(
        string _cloneTokenName,
        uint8 _cloneDecimalUnits,
        string _cloneTokenSymbol,
        uint _snapshotBlock,
        bool _transfersEnabled
        ) public returns(address) {            
        if (_snapshotBlock == 0) _snapshotBlock = block.number;
        MiniMeToken cloneToken = tokenFactory.createCloneToken(
            this,
            _snapshotBlock,
            _cloneTokenName,
            _cloneDecimalUnits,
            _cloneTokenSymbol,
            _transfersEnabled
            );

        cloneToken.transferControl(msg.sender);

         
        NewCloneToken(address(cloneToken), _snapshotBlock);
        return address(cloneToken);
    }

 
 
 

     
     
     
     
    function generateTokens(address _owner, uint _amount
    ) public onlyController returns (bool) {
        uint curTotalSupply = totalSupply();
        require(curTotalSupply + _amount >= curTotalSupply);  
        uint previousBalanceTo = balanceOf(_owner);
        require(previousBalanceTo + _amount >= previousBalanceTo);  
        updateValueAtNow(totalSupplyHistory, curTotalSupply + _amount);
        updateValueAtNow(balances[_owner], previousBalanceTo + _amount);
        Transfer(address(0x0), _owner, _amount);
        return true;
    }


     
     
     
     
    function destroyTokens(address _owner, uint _amount
    ) onlyController public returns (bool) {
        uint curTotalSupply = totalSupply();
        require(curTotalSupply >= _amount);
        uint previousBalanceFrom = balanceOf(_owner);
        require(previousBalanceFrom >= _amount);
        updateValueAtNow(totalSupplyHistory, curTotalSupply - _amount);
        updateValueAtNow(balances[_owner], previousBalanceFrom - _amount);
        Transfer(_owner, address(0x0), _amount);
        return true;
    }

 
 
 


     
     
    function enableTransfers(bool _transfersEnabled) public onlyController {
        transfersEnabled = _transfersEnabled;
    }

 
 
 

     
     
     
     
    function getValueAt(Checkpoint[] storage checkpoints, uint _block
    ) constant internal returns (uint) {
        if (checkpoints.length == 0) return 0;

         
        if (_block >= checkpoints[checkpoints.length-1].fromBlock)
            return checkpoints[checkpoints.length-1].value;
        if (_block < checkpoints[0].fromBlock) return 0;

         
        uint min = 0;
        uint max = checkpoints.length-1;
        while (max > min) {
            uint mid = (max + min + 1)/ 2;
            if (checkpoints[mid].fromBlock<=_block) {
                min = mid;
            } else {
                max = mid-1;
            }
        }
        return checkpoints[min].value;
    }

     
     
     
     
    function updateValueAtNow(Checkpoint[] storage checkpoints, uint _value
    ) internal  {
        if ((checkpoints.length == 0)
        || (checkpoints[checkpoints.length -1].fromBlock < block.number)) {
               Checkpoint storage newCheckPoint = checkpoints[ checkpoints.length++ ];
               newCheckPoint.fromBlock =  uint128(block.number);
               newCheckPoint.value = uint128(_value);
           } else {
               Checkpoint storage oldCheckPoint = checkpoints[checkpoints.length-1];
               oldCheckPoint.value = uint128(_value);
           }
    }

     
     
     
    function isContract(address _addr) constant internal returns(bool) {
        uint size;
        if (_addr == address(0x0)) return false;
        assembly {
            size := extcodesize(_addr)
        }
        return size>0;
    }

     
    function min(uint a, uint b) pure internal returns (uint) {
        return a < b ? a : b;
    }

     
     
     
     
         
         
     

 
 
 

     
     
     
     
    function claimTokens(address _token) public onlyController {
        if (_token == address(0x0)) {
            controller.transfer(this.balance);
            return;
        }

        MiniMeToken token = MiniMeToken(_token);
        uint balance = token.balanceOf(this);
        token.transfer(controller, balance);
        ClaimedTokens(_token, controller, balance);
    }

 
 
 
    event ClaimedTokens(address indexed _token, address indexed _controller, uint _amount);
    event Transfer(address indexed _from, address indexed _to, uint256 _amount);
    event NewCloneToken(address indexed _cloneToken, uint _snapshotBlock);
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _amount
        );

}


 
 
 

 
 
 
contract MiniMeTokenFactory {

     
     
     
     
     
     
     
     
     
     
    function createCloneToken(
        address _parentToken,
        uint _snapshotBlock,
        string _tokenName,
        uint8 _decimalUnits,
        string _tokenSymbol,
        bool _transfersEnabled
    ) public returns (MiniMeToken) {
        MiniMeToken newToken = new MiniMeToken(
            this,
            _parentToken,
            _snapshotBlock,
            _tokenName,
            _decimalUnits,
            _tokenSymbol,
            _transfersEnabled
            );

        newToken.transferControl(msg.sender);
        return newToken;
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





 
contract Pausable is Controlled {
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

   
  function pause() onlyController whenNotPaused public {
    paused = true;
    Pause();
  }

   
  function unpause() onlyController whenPaused public {
    paused = false;
    Unpause();
  }
}

contract CrowdSale is Pausable {
    using SafeMath for uint256;
    
    uint256 public startFundingTime = 1517990460;  
    uint256 public endFundingTime = 1523779200;    
        
    uint256 public totalEtherCollected;            
    uint256 public totalTokensSold;                
    
    uint256 public etherToUSDrate = 800;           
    
    MiniMeToken public tokenContract;              
    
    address public etherVault = 0x674552169ec1683Aa26aa7406337FAc67BF31ED5;  
    address public unsoldTokensVault = 0x5316e0A703a584ECa2e95B73B4E6dB8E98E089e0;  
 
    address public tokenVault;                     
    
     
    event Purchase(address investor, uint256 weiReceived, uint256 tokensSold);
    
     
     
    function CrowdSale(address _tokenAddress) public {
        require (_tokenAddress != address(0));            
        
        tokenContract = MiniMeToken(_tokenAddress);     

        tokenVault = msg.sender;
    }
    
     
    function () public whenNotPaused payable {
        doPayment(msg.sender);
    }
    
     
    function doPayment(address _owner) internal {

         
        require ((now >= startFundingTime) && (now <= endFundingTime) && (msg.value != 0));
        
         
        uint256 tokens = calculateTokens(msg.value);
           
         
        totalEtherCollected = totalEtherCollected.add(msg.value);
         
        totalTokensSold = totalTokensSold.add(tokens);        

         
        require (etherVault.send(msg.value));

         
         
        require (tokenContract.transferFrom(tokenVault, _owner, tokens));
        
         
        Purchase(_owner, msg.value, tokens);
        
        return;
    }
    
     
    function calculateTokens(uint256 _wei) internal view returns (uint256) {
 
        uint256 weiAmount = _wei;
        uint256 USDamount = (weiAmount.mul(etherToUSDrate)).div(10**14);  

        uint256 purchaseAmount; 
        uint256 withBonus;
 
         
        if(now < 1518595200) {
            purchaseAmount = USDamount;  
             
            if(purchaseAmount < 10000 || purchaseAmount > 3500000000) {
                 revert();
            }
            else {
                 withBonus = purchaseAmount.mul(19);  
                 return withBonus;
            }   
        }
 
         
        else if(now >= 1518595200 && now < 1518681600) {
            purchaseAmount = USDamount;  
             
            if(purchaseAmount < 10000 || purchaseAmount > 3500000000) {
                 revert();
            }
            else {
                 withBonus = purchaseAmount.mul(18);  
                 return withBonus;
            }   
        }

         
        else if(now >= 1518681600 && now < 1519286400) {
            purchaseAmount = USDamount;  
             
            if(purchaseAmount < 10000 || purchaseAmount > 3500000000) {
                revert();
            }     
            else {
                if(weiAmount >= 500 finney && weiAmount < 1 ether) {
                    withBonus = purchaseAmount.mul(11);  
                    return withBonus;
                }
                else if(weiAmount >= 1 ether) {
                    withBonus = purchaseAmount.mul(16);  
                    return withBonus;                
                }
                else {
                    withBonus = purchaseAmount.mul(10);  
                    return withBonus;
                }
            }
        }

         
        else if(now >= 1519286400 && now < 1519891200) {
            purchaseAmount = USDamount;  
             
            if(purchaseAmount < 10000 || purchaseAmount > 3500000000) {
                revert();
            }
            else {
                if(weiAmount >= 500 finney && weiAmount < 1 ether) {
                    withBonus = purchaseAmount.mul(11);  
                    return withBonus;
                }
                else if(weiAmount >= 1 ether) {
                    withBonus = purchaseAmount.mul(15);  
                    return withBonus;                
                }
                else {
                    withBonus = purchaseAmount.mul(10);  
                    return withBonus;
                }
            }
        }

         
        else if(now >= 1519891200 && now < 1521100800) {
            purchaseAmount = (USDamount.mul(10)).div(14);  
            if(purchaseAmount < 10000 || purchaseAmount > 3500000000) {
                revert();
            }
            else {
                if(weiAmount >= 500 finney && weiAmount < 1 ether) {
                    withBonus = purchaseAmount.mul(11);  
                    return withBonus;
                }
                else if(weiAmount >= 1 ether && weiAmount < 5 ether) {
                    withBonus = purchaseAmount.mul(13);  
                    return withBonus;
                }
                else if(weiAmount >= 5 ether && weiAmount < 8 ether) {
                    withBonus = purchaseAmount.mul(14);  
                    return withBonus;
                }              
                else if(weiAmount >= 8 ether) {
                    withBonus = purchaseAmount.mul(15);  
                    return withBonus;
                }
                else {
                    withBonus = purchaseAmount.mul(10);  
                    return withBonus;
                }              
            }
        }  

         
        else if(now >= 1521100800 && now < 1522569600) {
            purchaseAmount = (USDamount.mul(10)).div(19);  
             
            if(purchaseAmount < 10000 || purchaseAmount > 3500000000) {
                revert();
            }
            else {
                if(weiAmount >= 500 finney && weiAmount < 1 ether) {
                    withBonus = purchaseAmount.mul(11);  
                    return withBonus;
                } 
                else if(weiAmount >= 1 ether && weiAmount < 5 ether) {
                    withBonus = purchaseAmount.mul(13);  
                    return withBonus;
                }
                else if(weiAmount >= 5 ether && weiAmount < 8 ether) {
                    withBonus = purchaseAmount.mul(14);  
                    return withBonus;               
                }              
                else if(weiAmount >= 8 ether) {
                    withBonus = purchaseAmount.mul(15);  
                    return withBonus;               
                }              
                else {
                    withBonus = purchaseAmount.mul(10);  
                    return withBonus;               
                }
            }
        }

         
        else if(now > 1522569600 && now <= endFundingTime) {
            purchaseAmount = (USDamount.mul(10)).div(27);  
             
            if(purchaseAmount < 10000 || purchaseAmount > 3500000000) {
                revert();
            }
            else{
                if(weiAmount >= 500 finney && weiAmount < 1 ether) {
                    withBonus = purchaseAmount.mul(11);  
                    return withBonus;
                }
                else if(weiAmount >= 1 ether && weiAmount < 5 ether) {
                    withBonus = purchaseAmount.mul(13);  
                    return withBonus;               
                }
                else if(weiAmount >= 5 ether && weiAmount < 8 ether) {
                    withBonus = purchaseAmount.mul(14);  
                    return withBonus;               
                }              
                else if(weiAmount >= 8 ether) {
                    withBonus = purchaseAmount.mul(15);  
                    return withBonus;              
                }              
                else {
                    withBonus = purchaseAmount.mul(10);  
                    return withBonus;               
                }
            }
        }
    }
    
     
    function setVault(address _newVaultAddress) public onlyController whenPaused {
        etherVault = _newVaultAddress;
    }
    
     
    function setEthToUSDRate(uint256 _rate) public onlyController whenPaused {
        etherToUSDrate = _rate;
    }    
        
     
    function finalizeFunding() public onlyController {
        require(now >= endFundingTime);
        uint256 unsoldTokens = tokenContract.allowance(tokenVault, address(this));
        if(unsoldTokens > 0) {
            require (tokenContract.transferFrom(tokenVault, unsoldTokensVault, unsoldTokens));
        }
        selfdestruct(etherVault);
    }
    
}