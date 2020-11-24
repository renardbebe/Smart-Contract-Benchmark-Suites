 

pragma solidity ^0.4.10;

contract GasToken2 {
     
     
     
     
     
    
    uint256 constant ADDRESS_BYTES = 20;
    uint256 constant MAX_SINGLE_BYTE = 128;
    uint256 constant MAX_NONCE = 256**9 - 1;

     
    function count_bytes(uint256 n) constant internal returns (uint256 c) {
        uint i = 0;
        uint mask = 1;
        while (n >= mask) {
            i += 1;
            mask *= 256;
        }

        return i;
    }

    function mk_contract_address(address a, uint256 n) constant internal returns (address rlp) {
         
        require(n <= MAX_NONCE);

         
        uint256 nonce_bytes;
         
        uint256 nonce_rlp_len;

        if (0 < n && n < MAX_SINGLE_BYTE) {
             
             
            nonce_bytes = 1;
            nonce_rlp_len = 1;
        } else {
             
            nonce_bytes = count_bytes(n);
            nonce_rlp_len = nonce_bytes + 1;
        }

         
        uint256 tot_bytes = 1 + ADDRESS_BYTES + nonce_rlp_len;

         
         
        uint256 word = ((192 + tot_bytes) * 256**31) +
                       ((128 + ADDRESS_BYTES) * 256**30) +
                       (uint256(a) * 256**10);

        if (0 < n && n < MAX_SINGLE_BYTE) {
            word += n * 256**9;
        } else {
            word += (128 + nonce_bytes) * 256**9;
            word += n * 256**(9 - nonce_bytes);
        }

        uint256 hash;

        assembly {
            let mem_start := mload(0x40)         
            mstore(0x40, add(mem_start, 0x20))   

            mstore(mem_start, word)              
            hash := sha3(mem_start,
                         add(tot_bytes, 1))      
        }

         
        return address(hash);
    }
    
     
     
     

     
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
    string constant public symbol = "GST2";

     
     
     
     
     
     
     
     
     
     
    uint256 s_head;
    uint256 s_tail;

     
     
     
    function totalSupply() public constant returns (uint256 supply) {
        return s_head - s_tail;
    }

     
    function makeChild() internal returns (address addr) {
        assembly {
             
             
             
             
             
             
             
             
             
             
             
             
             
             
             
             
             
             
             
             
             
             
             
             
             
            let solidity_free_mem_ptr := mload(0x40)
            mstore(solidity_free_mem_ptr, 0x00756eb3f879cb30fe243b4dfee438691c043318585733ff6000526016600af3)
            addr := create(0, add(solidity_free_mem_ptr, 1), 31)
        }
    }

     
     
     
    function mint(uint256 value) public {
        for (uint256 i = 0; i < value; i++) {
            makeChild();
        }
        s_head += value;
        s_balances[msg.sender] += value;
    }

     
     
     
     
     
     
     
     
     
     
     
    function destroyChildren(uint256 value) internal {
        uint256 tail = s_tail;
         
        for (uint256 i = tail + 1; i <= tail + value; i++) {
            mk_contract_address(this, i).call();
        }

        s_tail = tail + value;
    }

     
     
     
     
     
    function free(uint256 value) public returns (bool success) {
        uint256 from_balance = s_balances[msg.sender];
        if (value > from_balance) {
            return false;
        }

        destroyChildren(value);

        s_balances[msg.sender] = from_balance - value;

        return true;
    }

     
     
     
     
    function freeUpTo(uint256 value) public returns (uint256 freed) {
        uint256 from_balance = s_balances[msg.sender];
        if (value > from_balance) {
            value = from_balance;
        }

        destroyChildren(value);

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

        destroyChildren(value);

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

        destroyChildren(value);

        s_balances[from] = from_balance - value;
        from_allowances[spender] = spender_allowance - value;

        return value;
    }
}