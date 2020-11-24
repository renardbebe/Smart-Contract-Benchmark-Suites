 

pragma solidity ^0.4.24;

 


 
 
 
 
 
 
 
 
 
 
 
 
 
 
 


 
 
 
 
contract TokenController {

    function proxyPayments(address _owner) public payable returns(bool);
    function onTransfer(address _from, address _to, uint _amount) public returns(bool);
    function onApprove(address _owner, address _spender, uint _amount) public returns(bool);
}


 
 
 

contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 _amount, address _token, bytes _data) public;
}


 
 
 
 
contract EthertoteToken {

     
    string public name;                
    uint8 public decimals;             
    string public symbol;              
    uint public _totalSupply;
    
     
    string public version; 
    address public contractOwner;
    address public thisContractAddress;
    address public EthertoteAdminAddress;
    
    bool public tokenGenerationLock;             
    
     
    address public controller;
    
     
    address public relinquishOwnershipAddress = 0x0000000000000000000000000000000000000000;
    
    
     
    modifier onlyController { 
        require(
            msg.sender == controller
            ); 
            _; 
    }
    
    
    modifier onlyContract { 
        require(
            address(this) == thisContractAddress
            
        ); 
        _; 
    }
    
    
    modifier EthertoteAdmin { 
        require(
            msg.sender == EthertoteAdminAddress
            
        ); 
        _; 
    }


     
     
     
    struct  Checkpoint {
        uint128 fromBlock;
        uint128 value;
    }

     
    EthertoteToken private parentToken;

     
     
    uint private parentSnapShotBlock;

     
    uint public creationBlock;

     
    mapping (address => Checkpoint[]) balances;

     
     
    mapping (address => mapping (address => uint256)) allowed;

     
    Checkpoint[] totalSupplyHistory;

     
    bool public transfersEnabled;


 
 
 
    constructor() public {
        
        controller = msg.sender;
        EthertoteAdminAddress = msg.sender;
        tokenGenerationLock = false;
        
     
     
     
    
        name = "Ethertote";                                    
        symbol = "TOTE";                                  
        decimals = 0;                                        
        _totalSupply = 10000000 * 10**uint(decimals);        
        
        version = "Ethertote Token contract - version 1.0";
    
     

         
        contractOwner = msg.sender;
        thisContractAddress = address(this);

        transfersEnabled = true;                             
        
        creationBlock = block.number;                        


         
         
        generateTokens(contractOwner, _totalSupply);
        
         
         
        controller = relinquishOwnershipAddress;
    }


 
 
 
 

     
    function totalSupply() public constant returns (uint) {
        return totalSupplyAt(block.number);
    }
    
     
    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balanceOfAt(_owner, block.number);
    }

     
    function allowance(address _owner, address _spender
    ) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

     
    function transfer(address _to, uint256 _amount
    ) public returns (bool success) {
        
        require(transfersEnabled);
        
         
        require(_to != address(this) );
         
        require(_to != 0x0);
        doTransfer(msg.sender, _to, _amount);
        return true;
    }

     
    function approve(address _spender, uint256 _amount) public returns (bool success) {
        require(transfersEnabled);
        require((_amount == 0) || (allowed[msg.sender][_spender] == 0));
        if (isContract(controller)) {
            require(TokenController(controller).onApprove(msg.sender, _spender, _amount));
        }

        allowed[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _amount
    ) public returns (bool success) {
        
         
        require(_to != address(this) );
         
        require(_to != 0x0);
        
        if (msg.sender != controller) {
            require(transfersEnabled);

            require(allowed[_from][msg.sender] >= _amount);
            allowed[_from][msg.sender] -= _amount;
        }
        doTransfer(_from, _to, _amount);
        return true;
    }
    
 
 
 

    event Transfer(
        address indexed _from, address indexed _to, uint256 _amount
        );
    
    event Approval(
        address indexed _owner, address indexed _spender, uint256 _amount
        );

 

     
    function changeController(address _newController) onlyController private {
        controller = _newController;
    }
    
    function doTransfer(address _from, address _to, uint _amount) internal {

           if (_amount == 0) {
               emit Transfer(_from, _to, _amount); 
               return;
           }

           require(parentSnapShotBlock < block.number);

            
            
           
           require(_to != address(this));
           
           

            
            
           uint previousBalanceFrom = balanceOfAt(_from, block.number);
           require(previousBalanceFrom >= _amount);

            
           if (isContract(controller)) {
               require(TokenController(controller).onTransfer(_from, _to, _amount));
           }

            
            
           updateValueAtNow(balances[_from], previousBalanceFrom - _amount);

            
            
           uint previousBalanceTo = balanceOfAt(_to, block.number);
           
            
           require(previousBalanceTo + _amount >= previousBalanceTo); 
           updateValueAtNow(balances[_to], previousBalanceTo + _amount);

            
           emit Transfer(_from, _to, _amount);

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




 
 
 
    function balanceOfAt(address _owner, uint _blockNumber) public constant
        returns (uint) {

        if ((balances[_owner].length == 0)
            || (balances[_owner][0].fromBlock > _blockNumber)) {
            if (address(parentToken) != 0) {
                return parentToken.balanceOfAt(_owner, min(_blockNumber, parentSnapShotBlock));
            } else {
                return 0;
            }

        } 
        
        else {
            return getValueAt(balances[_owner], _blockNumber);
        }
    }


 
 
 
 
    function totalSupplyAt(uint _blockNumber) public constant returns(uint) {
        if (
            (totalSupplyHistory.length == 0) ||
            (totalSupplyHistory[0].fromBlock > _blockNumber)
            ) {
            if (address(parentToken) != 0) {
                return parentToken.totalSupplyAt(min(_blockNumber, parentSnapShotBlock));
            } else {
                return 0;
            }

        } 
        else {
            return getValueAt(totalSupplyHistory, _blockNumber);
        }
    }


 
 
 
 
 
    function generateTokens(address _owner, uint _theTotalSupply) 
    private onlyContract returns (bool) {
        require(tokenGenerationLock == false);
        uint curTotalSupply = totalSupply();
        require(curTotalSupply + _theTotalSupply >= curTotalSupply);  
        uint previousBalanceTo = balanceOf(_owner);
        require(previousBalanceTo + _totalSupply >= previousBalanceTo);  
        updateValueAtNow(totalSupplyHistory, curTotalSupply + _totalSupply);
        updateValueAtNow(balances[_owner], previousBalanceTo + _totalSupply);
        emit Transfer(0, _owner, _totalSupply);
        tokenGenerationLock = true;
        return true;
    }


 
 
 

    function enableTransfers(bool _transfersEnabled) private onlyController {
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
        if (_addr == 0) return false;
        assembly {
            size := extcodesize(_addr)
        }
        return size>0;
    }

 
 
 
    function min(uint a, uint b) pure internal returns (uint) {
        return a < b ? a : b;
    }

 
 
 
 
 
    function () public payable {
        require(isContract(controller));
        require(
            TokenController(controller).proxyPayments.value(msg.value)(msg.sender)
            );
    }


    event ClaimedTokens(
        address indexed _token, address indexed _controller, uint _amount
        );

 
 
 
 
 
 
    function withdrawOtherTokens(address _token) EthertoteAdmin public {
        if (_token == 0x0) {
            controller.transfer(address(this).balance);
            return;
        }
        EthertoteToken token = EthertoteToken(_token);
        uint balance = token.balanceOf(this);
        token.transfer(controller, balance);
        emit ClaimedTokens(_token, controller, balance);
    }

}