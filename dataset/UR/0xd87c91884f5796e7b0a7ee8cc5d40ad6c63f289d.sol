 

pragma solidity ^0.4.11;

 

 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 


 
 

 
 
 
contract Token { 
    function totalSupply() constant returns (uint256 supply);
    function balanceOf(address _owner) constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
    function approve(address _spender, uint256 _value) returns (bool success);
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


 
 
 
contract E4LavaRewards
{
        function checkDividends(address _addr) constant returns(uint _amount);
        function withdrawDividends() public returns (uint namount);
        function transferDividends(address _to) returns (bool success);

}

 
 
 
contract E4Lava is Token, E4LavaRewards {
        event StatEvent(string msg);
        event StatEventI(string msg, uint val);

        enum SettingStateValue  {debug, lockedRelease}

        struct tokenAccount {
                bool alloced;        
                uint tokens;         
                uint currentPoints;  
                uint lastSnapshot;   
        }

 
 
 
        uint constant NumOrigTokens         = 5762;    
        uint constant NewTokensPerOrigToken = 100000;  
        uint constant NewTokenSupply        = 5762 * 100000;
        uint public numToksSwitchedOver;               
        uint public holdoverBalance;                   
        uint public TotalFeesReceived;                 

        address public developers;                     
        address public owner;                          
        address public oldE4;                          
        address public oldE4RecycleBin;   

        uint public decimals;
        string public symbol;

        mapping (address => tokenAccount) holderAccounts;           
        mapping (uint => address) holderIndexes;                    
        mapping (address => mapping (address => uint256)) allowed;  
        uint public numAccounts;

        uint public payoutThreshold;                   
        uint public vestTime;                          
        uint public rwGas;                             
        uint public optInGas;

        SettingStateValue public settingsState;


         
         
         
        function E4Lava() 
        {
                owner = msg.sender;
                developers = msg.sender;
                decimals = 2;
                symbol = "E4ROW";
        }

         
         
         
        function applySettings(SettingStateValue qState, uint _threshold, uint _vest, uint _rw, uint _optGas )
        {
                if (msg.sender != owner) 
                        return;

                 
                payoutThreshold = _threshold;
                rwGas = _rw;
                optInGas = _optGas;

                 
                if (settingsState == SettingStateValue.lockedRelease)
                        return;

                settingsState = qState;

                 
                 
                 

                if (qState == SettingStateValue.lockedRelease) {
                        StatEvent("Locking!");
                        return;
                }

                 
                 
                 

                for (uint i = 0; i < numAccounts; i++ ) {
                        address a = holderIndexes[i];
                        if (a != address(0)) {
                                holderAccounts[a].tokens = 0;
                                holderAccounts[a].currentPoints = 0;
                                holderAccounts[a].lastSnapshot = 0;
                        }
                }

                vestTime = _vest;
                numToksSwitchedOver = 0;

                if (this.balance > 0) {
                        if (!owner.call.gas(rwGas).value(this.balance)())
                                StatEvent("ERROR!");
                }
                StatEvent("ok");

        }


         
         
         
         
        function addAccount(address _addr) internal  {
                holderAccounts[_addr].alloced = true;
                holderAccounts[_addr].tokens = 0;
                holderAccounts[_addr].currentPoints = 0;
                holderAccounts[_addr].lastSnapshot = TotalFeesReceived;
                holderIndexes[numAccounts++] = _addr;
        }


 
 
 

        function totalSupply() constant returns (uint256 supply)
        {
                supply = NewTokenSupply;
        }

         
         
         
         
        function transfer(address _to, uint256 _value) returns (bool success) 
        {
                if ((msg.sender == developers) 
                        &&  (now < vestTime)) {
                         
                        return false;
                }

                 
                 
                 
                 
                if (holderAccounts[msg.sender].tokens >= _value && _value > 0) {
                     
                    calcCurPointsForAcct(msg.sender);
                    holderAccounts[msg.sender].tokens -= _value;
                    
                    if (!holderAccounts[_to].alloced) {
                        addAccount(_to);
                    }
                     
                    calcCurPointsForAcct(_to);
                    holderAccounts[_to].tokens += _value;

                    Transfer(msg.sender, _to, _value);
                    return true;
                } else { 
                    return false; 
                }
        }


        function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
                if ((_from == developers) 
                        &&  (now < vestTime)) {
                         
                        return false;
                }

                 
                 
                if (holderAccounts[_from].tokens >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {

                    calcCurPointsForAcct(_from);
                    holderAccounts[_from].tokens -= _value;
                    
                    if (!holderAccounts[_to].alloced) {
                        addAccount(_to);
                    }
                     
                    calcCurPointsForAcct(_to);
                    holderAccounts[_to].tokens += _value;

                    allowed[_from][msg.sender] -= _value;
                    Transfer(_from, _to, _value);
                    return true;
                } else { 
                    return false; 
                }
        }


        function balanceOf(address _owner) constant returns (uint256 balance) {
                balance = holderAccounts[_owner].tokens;
        }

        function approve(address _spender, uint256 _value) returns (bool success) {
                allowed[msg.sender][_spender] = _value;
                Approval(msg.sender, _spender, _value);
                return true;
        }

        function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
                return allowed[_owner][_spender];
        }
 
 
 

         
         
         
         
         
         
        function calcCurPointsForAcct(address _acct) {
              holderAccounts[_acct].currentPoints += (TotalFeesReceived - holderAccounts[_acct].lastSnapshot) * holderAccounts[_acct].tokens;
              holderAccounts[_acct].lastSnapshot = TotalFeesReceived;
        }


         
         
         
         
         
        function () payable {
                holdoverBalance += msg.value;
                TotalFeesReceived += msg.value;
                StatEventI("Payment", msg.value);
        }

         
         
         
        function blackHole() payable {
                StatEventI("adjusted", msg.value);
        }

         
         
         
        function withdrawDividends() public returns (uint _amount)
        {
                calcCurPointsForAcct(msg.sender);

                _amount = holderAccounts[msg.sender].currentPoints / NewTokenSupply;
                if (_amount <= payoutThreshold) {
                        StatEventI("low Balance", _amount);
                        return;
                } else {
                        if ((msg.sender == developers) 
                                &&  (now < vestTime)) {
                                StatEvent("Tokens not yet vested.");
                                _amount = 0;
                                return;
                        }

                        uint _pointsUsed = _amount * NewTokenSupply;
                        holderAccounts[msg.sender].currentPoints -= _pointsUsed;
                        holdoverBalance -= _amount;
                        if (!msg.sender.call.gas(rwGas).value(_amount)())
                                throw;
                }
        }

         
         
         
        function transferDividends(address _to) returns (bool success) 
        {
                if ((msg.sender == developers) 
                        &&  (now < vestTime)) {
                         
                        return false;
                }
                calcCurPointsForAcct(msg.sender);
                if (holderAccounts[msg.sender].currentPoints == 0) {
                        StatEvent("Zero balance");
                        return false;
                }
                if (!holderAccounts[_to].alloced) {
                        addAccount(_to);
                }
                calcCurPointsForAcct(_to);
                holderAccounts[_to].currentPoints += holderAccounts[msg.sender].currentPoints;
                holderAccounts[msg.sender].currentPoints = 0;
                StatEvent("Trasnfered Dividends");
                return true;
        }



         
         
         
        function setOpGas(uint _rw, uint _optIn)
        {
                if (msg.sender != owner && msg.sender != developers) {
                         
                        return;
                } else {
                        rwGas = _rw;
                        optInGas = _optIn;
                }
        }


         
         
         
        function checkDividends(address _addr) constant returns(uint _amount)
        {
                if (holderAccounts[_addr].alloced) {
                    
                   uint _currentPoints = holderAccounts[_addr].currentPoints + 
                        ((TotalFeesReceived - holderAccounts[_addr].lastSnapshot) * holderAccounts[_addr].tokens);
                   _amount = _currentPoints / NewTokenSupply;

                 
                   
                   
                   

                }
        }



         
         
         
        function changeOwner(address _addr) 
        {
                if (msg.sender != owner
                        || settingsState == SettingStateValue.lockedRelease)
                         throw;
                owner = _addr;
        }

         
         
         
        function setDeveloper(address _addr) 
        {
                if (msg.sender != owner
                        || settingsState == SettingStateValue.lockedRelease)
                         throw;
                developers = _addr;
        }

         
         
         
        function setOldE4(address _oldE4, address _oldE4Recyle) 
        {
                if (msg.sender != owner
                        || settingsState == SettingStateValue.lockedRelease)
                         throw;
                oldE4 = _oldE4;
                oldE4RecycleBin = _oldE4Recyle;
        }



         
         
         
        function haraKiri()
        {
                if (settingsState != SettingStateValue.debug)
                        throw;
                if (msg.sender != owner)
                         throw;
                suicide(developers);
        }


         
         
         
         
         
         
         
         
         
        function optInFromClassic() public
        {
                if (oldE4 == address(0)) {
                        StatEvent("config err");
                        return;
                }
                 
                address nrequester = msg.sender;

                 
                 
                 
                if (holderAccounts[nrequester].tokens != 0) {
                        StatEvent("Account has already been allocd!");
                        return;
                }

                 
                Token iclassic = Token(oldE4);
                uint _toks = iclassic.balanceOf(nrequester);
                if (_toks == 0) {
                        StatEvent("Nothing to do");
                        return;
                }

                 
                if (iclassic.allowance(nrequester, address(this)) < _toks) {
                        StatEvent("Please approve this contract to transfer");
                        return;
                }

                 
                iclassic.transferFrom.gas(optInGas)(nrequester, oldE4RecycleBin, _toks);

                 
                if (iclassic.balanceOf(nrequester) == 0) {
                         
                        if (!holderAccounts[nrequester].alloced)
                                addAccount(nrequester);
                        holderAccounts[nrequester].tokens = _toks * NewTokensPerOrigToken;
                        holderAccounts[nrequester].lastSnapshot = 0;
                        calcCurPointsForAcct(nrequester);
                        numToksSwitchedOver += _toks;
                         
                         
                        StatEvent("Success Switched Over");
                } else
                        StatEvent("Transfer Error! please contact Dev team!");


        }

}