 

pragma solidity ^0.4.10;

contract GasToken1 {
     
     
     

     
    mapping(address => uint256) s_balances;
     
    mapping(address => mapping(address => uint256)) s_allowances;

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

     
    function balanceOf(address owner) public constant returns (uint256 balance) {
        return s_balances[owner];
    }

    function internalTransfer(address from, address to, uint256 value) internal returns (bool success) {
        if (value <= s_balances[from]) {
            s_balances[from] -= value;
            s_balances[to] += value;
            Transfer(from, to, value);
            return true;
        } else {
            return false;
        }
    }

     
    function transfer(address to, uint256 value) public returns (bool success) {
        address from = msg.sender;
        return internalTransfer(from, to, value);
    }

     
    function transferFrom(address from, address to, uint256 value) public returns (bool success) {
        address spender = msg.sender;
        if(value <= s_allowances[from][spender] && internalTransfer(from, to, value)) {
            s_allowances[from][spender] -= value;
            return true;
        } else {
            return false;
        }
    }

     
     
     
    function approve(address spender, uint256 value) public returns (bool success) {
        address owner = msg.sender;
        if (value != 0 && s_allowances[owner][spender] != 0) {
            return false;
        }
        s_allowances[owner][spender] = value;
        Approval(owner, spender, value);
        return true;
    }

     
     
     
     
     
    function allowance(address owner, address spender) public constant returns (uint256 remaining) {
        return s_allowances[owner][spender];
    }

     
     
     

    uint8 constant public decimals = 2;
    string constant public name = "Gastoken.io";
    string constant public symbol = "GST1";

     
     
     
    uint256 constant STORAGE_LOCATION_ARRAY = 0xDEADBEEF;


     
    function totalSupply() public constant returns (uint256 supply) {
        uint256 storage_location_array = STORAGE_LOCATION_ARRAY;
        assembly {
            supply := sload(storage_location_array)
        }
    }

     
     
     
    function mint(uint256 value) public {
        uint256 storage_location_array = STORAGE_LOCATION_ARRAY;   

        if (value == 0) {
            return;
        }

         
        uint256 supply;
        assembly {
            supply := sload(storage_location_array)
        }

         
        uint256 l = storage_location_array + supply + 1;
        uint256 r = storage_location_array + supply + value;
        assert(r >= l);

        for (uint256 i = l; i <= r; i++) {
            assembly {
                sstore(i, 1)
            }
        }

         
        assembly {
            sstore(storage_location_array, add(supply, value))
        }
        s_balances[msg.sender] += value;
    }

    function freeStorage(uint256 value) internal {
        uint256 storage_location_array = STORAGE_LOCATION_ARRAY;   

         
        uint256 supply;
        assembly {
            supply := sload(storage_location_array)
        }

         
        uint256 l = storage_location_array + supply - value + 1;
        uint256 r = storage_location_array + supply;
        for (uint256 i = l; i <= r; i++) {
            assembly {
                sstore(i, 0)
            }
        }

         
        assembly {
            sstore(storage_location_array, sub(supply, value))
        }
    }

     
     
     
    function free(uint256 value) public returns (bool success) {
        uint256 from_balance = s_balances[msg.sender];
        if (value > from_balance) {
            return false;
        }

        freeStorage(value);

        s_balances[msg.sender] = from_balance - value;

        return true;
    }

     
     
    function freeUpTo(uint256 value) public returns (uint256 freed) {
        uint256 from_balance = s_balances[msg.sender];
        if (value > from_balance) {
            value = from_balance;
        }

        freeStorage(value);

        s_balances[msg.sender] = from_balance - value;

        return value;
    }

     
     
    function freeFrom(address from, uint256 value) public returns (bool success) {
        address spender = msg.sender;
        uint256 from_balance = s_balances[from];
        if (value > from_balance) {
            return false;
        }

        mapping(address => uint256) from_allowances = s_allowances[from];
        uint256 spender_allowance = from_allowances[spender];
        if (value > spender_allowance) {
            return false;
        }

        freeStorage(value);

        s_balances[from] = from_balance - value;
        from_allowances[spender] = spender_allowance - value;

        return true;
    }

     
     
    function freeFromUpTo(address from, uint256 value) public returns (uint256 freed) {
        address spender = msg.sender;
        uint256 from_balance = s_balances[from];
        if (value > from_balance) {
            value = from_balance;
        }

        mapping(address => uint256) from_allowances = s_allowances[from];
        uint256 spender_allowance = from_allowances[spender];
        if (value > spender_allowance) {
            value = spender_allowance;
        }

        freeStorage(value);

        s_balances[from] = from_balance - value;
        from_allowances[spender] = spender_allowance - value;

        return value;
    }
}