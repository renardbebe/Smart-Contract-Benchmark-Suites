 

pragma solidity ^0.4.18;

 
 
contract Potatoin {
     
    string public constant name     = "Potatoin";
    string public constant symbol   = "POIN";
    uint8  public constant decimals = 0;

     
     
    uint public genesis;
    uint public relief;

     
    mapping(address => uint) public donated;

     
     
    uint public decay;
    uint public growth;

     
     
    address[]                farmers;
    mapping(address => uint) cellars;
    mapping(address => uint) trashes;
    mapping(address => uint) recycled;

     
     
    struct field {
        uint potatoes;
        uint sowed;
    }
    mapping(address => field[]) public fields;
    mapping(address => uint)    public empties;

     
    event Transfer(address indexed _from, address indexed _to, uint _value);

     
     
    function Potatoin(uint256 _relief, uint256 _decay, uint256 _growth) public {
        genesis = block.timestamp;
        relief  = _relief;
        decay   = _decay;
        growth  = _growth;
    }

     
     
    function totalSupply() constant public returns (uint totalSupply) {
        for (uint i = 0; i < farmers.length; i++) {
            totalSupply += balanceOf(farmers[i]);
        }
        return totalSupply;
    }

     
     
    function balanceOf(address farmer) constant public returns (uint256 balance) {
       return unsowed(farmer) + sowed(farmer);
    }

     
     
    function unsowed(address farmer) constant public returns (uint256 balance) {
         
        var elapsed = block.timestamp - recycled[farmer];
        if (elapsed < decay) {
            balance = (cellars[farmer] * (decay - elapsed) + decay-1) / decay;
        }
         
        var list = fields[farmer];
        for (uint i = empties[farmer]; i < list.length; i++) {
            elapsed = block.timestamp - list[i].sowed;
            if (elapsed >= growth && elapsed - growth < decay) {
                balance += (2 * list[i].potatoes * (decay-elapsed+growth) + decay-1) / decay;
            }
        }
        return balance;
    }

     
     
    function sowed(address farmer) constant public returns (uint256 balance) {
        var list = fields[farmer];
        for (uint i = empties[farmer]; i < list.length; i++) {
             
            var elapsed = block.timestamp - list[i].sowed;
            if (elapsed >= growth) {
                continue;
            }
             
            balance += list[i].potatoes + list[i].potatoes * elapsed / growth;
        }
        return balance;
    }

     
     
    function trashed(address farmer) constant public returns (uint256 balance) {
         
        balance = trashes[farmer];

         
        var elapsed = block.timestamp - recycled[farmer];
        if (elapsed >= 0) {
            var rotten = cellars[farmer];
            if (elapsed < decay) {
               rotten = cellars[farmer] * elapsed / decay;
            }
            balance += rotten;
        }
         
        var list = fields[farmer];
        for (uint i = empties[farmer]; i < list.length; i++) {
            elapsed = block.timestamp - list[i].sowed;
            if (elapsed >= growth) {
                rotten = 2 * list[i].potatoes;
                if  (elapsed - growth < decay) {
                    rotten = 2 * list[i].potatoes * (elapsed - growth) / decay;
                }
                balance += rotten;
            }
        }
        return balance;
    }

     
     
    function request() public {
         
        require(block.timestamp < genesis + relief);
        require(donated[msg.sender] == 0);

         
        donated[msg.sender] = block.timestamp;

        farmers.push(msg.sender);
        cellars[msg.sender] = 1;
        recycled[msg.sender] = block.timestamp;

        Transfer(this, msg.sender, 1);
    }

     
     
     
    function sow(uint potatoes) public {
         
        harvest(msg.sender);

         
        if (potatoes == 0) {
            return;
        }
         
        if (cellars[msg.sender] > 0) {
            if (potatoes > cellars[msg.sender]) {
                potatoes = cellars[msg.sender];
            }
            fields[msg.sender].push(field(potatoes, block.timestamp));
            cellars[msg.sender] -= potatoes;

            Transfer(msg.sender, this, potatoes);
        }
    }

     
     
     
    function harvest(address farmer) internal {
         
        recycle(farmer);

         
        var list = fields[farmer];
        for (uint i = empties[farmer]; i < list.length; i++) {
            var elapsed = block.timestamp - list[i].sowed;
            if (elapsed >= growth) {
                if (elapsed - growth < decay) {
                    var harvested = (2 * list[i].potatoes * (decay-elapsed+growth) + decay-1) / decay;
                    var rotten    = 2 * list[i].potatoes - harvested;

                    cellars[farmer] += harvested;
                    Transfer(this, farmer, harvested);

                    if (rotten > 0) {
                        trashes[farmer] += rotten;
                        Transfer(this, 0, rotten);
                    }
                } else {
                    trashes[farmer] += 2 * list[i].potatoes;
                    Transfer(this, 0, 2 * list[i].potatoes);
                }
                empties[farmer]++;
            }
        }
         
        if (empties[farmer] > 0 && empties[farmer] == list.length) {
            delete empties[farmer];
            delete fields[farmer];
        }
    }

     
    function recycle(address farmer) internal {
        var elapsed = block.timestamp - recycled[farmer];
        if (elapsed == 0) {
            return;
        }
        var rotten = cellars[farmer];
        if (elapsed < decay) {
           rotten = cellars[farmer] * elapsed / decay;
        }
        if (rotten > 0) {
            cellars[farmer] -= rotten;
            trashes[farmer] += rotten;

            Transfer(farmer, 0, rotten);
        }
        recycled[farmer] = block.timestamp;
    }

     
    function transfer(address to, uint potatoes) public returns (bool success) {
         
        harvest(msg.sender);
        if (cellars[msg.sender] < potatoes) {
            return false;
        }
         
        recycle(to);
        cellars[msg.sender] -= potatoes;
        cellars[to]         += potatoes;

        Transfer(msg.sender, to, potatoes);
        return true;
    }

     
    function transferFrom(address _from, address _to, uint _value) returns (bool success) {
        return false;
    }

     
    function approve(address _spender, uint _value) returns (bool success) {
        return false;
    }

     
    function allowance(address _owner, address _spender) constant returns (uint remaining) {
        return 0;
    }
}