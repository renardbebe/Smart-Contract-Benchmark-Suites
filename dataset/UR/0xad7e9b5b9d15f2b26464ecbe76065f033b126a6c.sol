 

pragma solidity ^0.4.18;

contract Random {

    uint public ticketsNum = 0;
    
    mapping(uint => uint) internal tickets;   
    mapping(uint => bool) internal payed_back;  
    
    address[] public addr;  
    
    uint32 public random_num = 0;  
 
    uint public liveBlocksNumber = 5760;  
    uint public startBlockNumber = 0;  
    uint public endBlockNumber = 0;  

    uint public constant onePotWei = 10000000000000000;  

    address public inv_contract = 0x5192c55B1064D920C15dB125eF2E69a17558E65a;  
    address public rtm_contract = 0x7E08c0468CBe9F48d8A4D246095dEb8bC1EB2e7e;  
    address public mrk_contract = 0xc01c08B2b451328947bFb7Ba5ffA3af96Cfc3430;  
    
    address manager;  
    
    uint public winners_count = 0;  
    uint last_winner = 0;  
    uint public others_prize = 0;  
    
    uint public fee_balance = 0;  

    
     
     
    
    event Buy(address indexed sender, uint eth);  
    event Withdraw(address indexed sender, address to, uint eth);  
    event Transfer(address indexed from, address indexed to, uint value);  
    event TransferError(address indexed to, uint value);  
    

     
    modifier onlyManager() {
        require(msg.sender == manager);
        _;
    }
    

     
    function Random() public {
        manager = msg.sender;
        startBlockNumber = block.number - 1;
        endBlockNumber = startBlockNumber + liveBlocksNumber;
    }


     
    function() public payable {
        require(block.number < endBlockNumber || msg.value < 1000000000000000000);
        if (msg.value > 0 && last_winner == 0) {
            uint val =  msg.value / onePotWei;
            uint i = 0;
            uint ix = checkAddress(msg.sender);
            for(i; i < val; i++) { tickets[ticketsNum+i] = ix; }
            ticketsNum += i;
            Buy(msg.sender, msg.value);
        }
        if (block.number >= endBlockNumber) { 
            EndLottery(); 
        }
    }


     
    function transfer(address _to, uint _ticketNum) public {
        if (msg.sender == getAddress(tickets[_ticketNum]) && _to != address(0)) {
            uint ix = checkAddress(_to);
            tickets[_ticketNum] = ix;
            Transfer(msg.sender, _to, _ticketNum);
        }
    }


     
    function manager_withdraw() onlyManager public {
        require(block.number >= endBlockNumber + liveBlocksNumber);
        msg.sender.transfer(this.balance);
    }
    
     
    function EndLottery() public payable returns (bool success) {
        require(block.number >= endBlockNumber); 
        uint tn = ticketsNum;
        if(tn < 3) { 
            tn = 0;
            if(msg.value > 0) { msg.sender.transfer(msg.value); }
            startNewDraw(msg.value);
            return false;
        }
        uint pf = prizeFund();
        uint jp1 = percent(pf, 10);
        uint jp2 = percent(pf, 4);
        uint jp3 = percent(pf, 1);
        uint lastbet_prize = onePotWei*10;
        
        if(last_winner == 0) {
            
            winners_count = percent(tn, 4) + 3; 
            
            uint prizes = jp1 + jp2 + jp3 + lastbet_prize*2;
            uint full_prizes = jp1 + jp2 + jp3 + (lastbet_prize * ( (winners_count+1)/10 ) );

            if(winners_count < 10) {
                if(prizes > pf) {
                    others_prize = 0;
                } else {
                    others_prize = pf - prizes;    
                }
            } else {
                if(full_prizes > pf) {
                    others_prize = 0;
                } else {
                    others_prize = pf - full_prizes;    
                }
            }

            sendEth(getAddress(tickets[getWinningNumber(1)]), jp1);
            sendEth(getAddress(tickets[getWinningNumber(2)]), jp2);
            sendEth(getAddress(tickets[getWinningNumber(3)]), jp3);
            last_winner += 1;
            
            sendEth(msg.sender, lastbet_prize + msg.value); 
            return true;
        } 
        
        if(last_winner < winners_count + 1 && others_prize > 0) {
            
            uint val = others_prize / winners_count;
            uint i;
            uint8 cnt = 0;
            for(i = last_winner; i < winners_count + 1; i++) {
                sendEth(getAddress(tickets[getWinningNumber(i+3)]), val);
                cnt++;
                if(cnt > 9) {
                    last_winner = i;
                    return true;
                }
            }
            last_winner = i;
            sendEth(msg.sender, lastbet_prize + msg.value);
            return true;
            
        } else {

            startNewDraw(lastbet_prize + msg.value);   
        }
        
        sendEth(msg.sender, lastbet_prize + msg.value);
        return true;
    }
    
     
    function startNewDraw(uint _msg_value) internal {
        ticketsNum = 0;
        startBlockNumber = block.number - 1;
        endBlockNumber = startBlockNumber + liveBlocksNumber;
        random_num += 1;
        winners_count = 0;
        last_winner = 0;
        fee_balance += (this.balance - _msg_value);
    }
    
     
    function payfee() public {
        require(fee_balance > 0);
        uint val = fee_balance;
        inv_contract.transfer( percent(val, 20) );
        rtm_contract.transfer( percent(val, 49) );
        mrk_contract.transfer( percent(val, 30) );
        fee_balance = 0;
    }
    
     
    function sendEth(address _to, uint _val) internal returns(bool) {
        if(this.balance < _val) {
            TransferError(_to, _val);
            return false;
        }
        _to.transfer(_val);
        Withdraw(address(this), _to, _val);
        return true;
    }
    
    
     
    function getWinningNumber(uint _blockshift) internal constant returns (uint) {
        return uint(block.blockhash(block.number - _blockshift)) % ticketsNum + 1;
    }
    

     
    function jackPotA() public view returns (uint) {
        return percent(prizeFund(), 10);
    }
    
     
    function jackPotB() public view returns (uint) {
        return percent(prizeFund(), 4);
    }
    
     
    function jackPotC() public view returns (uint) {
        return percent(prizeFund(), 1);
    }

     
    function prizeFund() public view returns (uint) {
        return ( (ticketsNum * onePotWei) / 100 ) * 90;
    }

     
    function percent(uint _val, uint8 _percent) public pure returns (uint) {
        return ( _val / 100 ) * _percent;
    }


     
    function getTicketOwner(uint _num) public view returns (address) {
        if(ticketsNum == 0) {
            return 0;
        }
        return getAddress(tickets[_num]);
    }

     
    function getTicketsCount(address _addr) public view returns (uint) {
        if(ticketsNum == 0) {
            return 0;
        }
        uint num = 0;
        for(uint i = 0; i < ticketsNum; i++) {
            if(tickets[i] == readAddress(_addr)) {
                num++;
            }
        }
        return num;
    }
    
     
    function getTicketsAtAdress(address _address) public view returns(uint[]) {
        uint[] memory result = new uint[](getTicketsCount(_address));
        uint num = 0;
        for(uint i = 0; i < ticketsNum; i++) {
            if(getAddress(tickets[i]) == _address) {
                result[num] = i;
                num++;
            }
        }
        return result;
    }


     
    function getLastWinner() public view returns(uint) {
        return last_winner+1;
    }


     
    function setInvContract(address _addr) onlyManager public {
        inv_contract = _addr;
    }

     
    function setRtmContract(address _addr) onlyManager public {
        rtm_contract = _addr;
    }

     
    function setMrkContract(address _addr) onlyManager public {
        mrk_contract = _addr;
    }


     
    function checkAddress(address _addr) public returns (uint addr_num)
    {
        for(uint i=0; i<addr.length; i++) {
            if(addr[i] == _addr) {
                return i;
            }
        }
        return addr.push(_addr) - 1;
    }
    
     
    function readAddress(address _addr) public view returns (uint addr_num)
    {
        for(uint i=0; i<addr.length; i++) {
            if(addr[i] == _addr) {
                return i;
            }
        }
        return 0;
    }

     
    function getAddress(uint _index) public view returns (address) {
        return addr[_index];
    }


     
    function deposit() public payable {
        require(msg.value > 0);
    }
    

}