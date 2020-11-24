 

 

pragma solidity ^0.4.11;

 

 
contract svb {
     
    uint constant totalSupplyDefault = 0;

    string public constant symbol = "SVB";
    string public constant name = "Silver";
    uint8 public constant decimals = 5;
     
    uint32 public constant minFee = 1;
    uint32 public constant minTransfer = 10;

    uint public totalSupply = 0;

     
    uint32 public transferFeeNum = 17;
    uint32 public transferFeeDenum = 10000;

     
     
     
    uint32 public demurringFeeNum = 13;
    uint32 public demurringFeeDenum = 1000000000;

    
     
    address public owner;
    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert();
        }
        _;
    }
    address public demurringFeeOwner;
    address public transferFeeOwner;
 
     
    mapping(address => uint) balances;

     
    mapping(address => uint64) timestamps;
 
     
    mapping(address => mapping (address => uint)) allowed;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed from , address indexed to , uint256 value);
    event DemurringFee(address indexed to , uint256 value);
    event TransferFee(address indexed to , uint256 value);

     
    function svb(uint supply) {
        if (supply > 0) {
            totalSupply = supply;
        } else {
            totalSupply = totalSupplyDefault;
        }
        owner = msg.sender;
        demurringFeeOwner = owner;
        transferFeeOwner = owner;
        balances[this] = totalSupply;
    }

    function changeDemurringFeeOwner(address addr) onlyOwner {
        demurringFeeOwner = addr;
    }
    function changeTransferFeeOwner(address addr) onlyOwner {
        transferFeeOwner = addr;
    }
 
    function balanceOf(address addr) constant returns (uint) {
        return balances[addr];
    }

     
     
    function chargeDemurringFee(address addr) internal {
        if (addr != owner && addr != transferFeeOwner && addr != demurringFeeOwner && balances[addr] > 0 && now > timestamps[addr] + 60) {
            var mins = (now - timestamps[addr]) / 60;
            var fee = balances[addr] * mins * demurringFeeNum / demurringFeeDenum;
            if (fee < minFee) {
                fee = minFee;
            } else if (fee > balances[addr]) {
                fee = balances[addr];
            }

            balances[addr] -= fee;
            balances[demurringFeeOwner] += fee;
            Transfer(addr, demurringFeeOwner, fee);
            DemurringFee(addr, fee);

            timestamps[addr] = uint64(now);
        }
    }

     
    function chargeTransferFee(address addr, uint amount) internal returns (uint) {
        if (addr != owner && addr != transferFeeOwner && addr != demurringFeeOwner && balances[addr] > 0) {
            var fee = amount * transferFeeNum / transferFeeDenum;
            if (fee < minFee) {
                fee = minFee;
            } else if (fee > balances[addr]) {
                fee = balances[addr];
            }
            amount = amount - fee;

            balances[addr] -= fee;
            balances[transferFeeOwner] += fee;
            Transfer(addr, transferFeeOwner, fee);
            TransferFee(addr, fee);
        }
        return amount;
    }
 
    function transfer(address to, uint amount) returns (bool) {
        if (amount >= minTransfer
            && balances[msg.sender] >= amount
            && balances[to] + amount > balances[to]
            ) {
                chargeDemurringFee(msg.sender);

                if (balances[msg.sender] >= amount) {
                    amount = chargeTransferFee(msg.sender, amount);

                     
                    if (balances[to] > 0) {
                        chargeDemurringFee(to);
                    } else {
                        timestamps[to] = uint64(now);
                    }

                    balances[msg.sender] -= amount;
                    balances[to] += amount;
                    Transfer(msg.sender, to, amount);
                }
                return true;
          } else {
              return false;
          }
    }
 
    function transferFrom(address from, address to, uint amount) returns (bool) {
        if ( amount >= minTransfer
            && allowed[from][msg.sender] >= amount
            && balances[from] >= amount
            && balances[to] + amount > balances[to]
            ) {
                allowed[from][msg.sender] -= amount;

                chargeDemurringFee(msg.sender);

                if (balances[msg.sender] >= amount) {
                    amount = chargeTransferFee(msg.sender, amount);

                     
                    if (balances[to] > 0) {
                        chargeDemurringFee(to);
                    } else {
                        timestamps[to] = uint64(now);
                    }

                    balances[msg.sender] -= amount;
                    balances[to] += amount;
                    Transfer(msg.sender, to, amount);
                }
                return true;
        } else {
            return false;
        }
    }
 
    function approve(address spender, uint amount) returns (bool) {
        allowed[msg.sender][spender] = amount;
        Approval(msg.sender, spender, amount);
        return true;
    }
 
    function allowance(address addr, address spender) constant returns (uint) {
        return allowed[addr][spender];
    }

    function setTransferFee(uint32 numinator, uint32 denuminator) onlyOwner {
        require(denuminator > 0 && numinator < denuminator);
        transferFeeNum = numinator;
        transferFeeDenum = denuminator;
    }

    function setDemurringFee(uint32 numinator, uint32 denuminator) onlyOwner {
        require(denuminator > 0 && numinator < denuminator);
        demurringFeeNum = numinator;
        demurringFeeDenum = denuminator;
    }

    function sell(address to, uint amount) onlyOwner {
        require(amount > minTransfer && balances[this] >= amount);

         
        if (balances[to] > 0) {
            chargeDemurringFee(to);
        } else {
            timestamps[to] = uint64(now);
        }
        balances[this] -= amount;
        balances[to] += amount;
        Transfer(this, to, amount);
    }

     
    function issue(uint amount) onlyOwner {
         if (totalSupply + amount > totalSupply) {
             totalSupply += amount;
             balances[this] += amount;
         }
    }

     
    function destroy(uint amount) onlyOwner {
          require(amount>0 && balances[this] >= amount);
          balances[this] -= amount;
          totalSupply -= amount;
    }

     
    function kill() onlyOwner {
        require (totalSupply == 0);
        selfdestruct(owner);
    }

     
    function () payable {
        revert();
    }
}