 

pragma solidity ^0.4.10;

contract TestToken {
    string  public name = "Test1";
    string  public symbol = "Test1";
    string  public standard = "DApp Token v1.0";
    uint256 public totalSupply;
    uint256 public decimals=18;
    uint256 public stage = 0;
    mapping(uint256 => uint256) public stages;
    uint256 public difference =0;
    uint256 public origin_block = 0;
    
    uint256 public loop = 0;
    
    uint256 lastBlockNumber;
    
    uint256 public dexamillions;
    uint256 public millions;
    uint256 public hundredks;
    uint256 public tenks;
    uint256 public ks;
    uint256 public hundreds;

    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 _value
    );

    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );

    mapping(address => uint256) public balanceOf;
    mapping(address => uint256) public lastTransactionBlockNumber;
    mapping(address => uint256) public temp_balances;
 

  
    
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b > 0);  
        uint256 c = a / b;
        assert(a == b * c + a % b);  
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

    constructor (uint256 _initialSupply) public {
        totalSupply = mul(_initialSupply, 10**(decimals));
        balanceOf[msg.sender] = totalSupply;
        temp_balances[msg.sender] = totalSupply;
        origin_block = block.number;
        lastTransactionBlockNumber[msg.sender] = origin_block;

    }
    
    
    function burn (address _add) public returns(bool success){
        
        if (lastTransactionBlockNumber[_add]!=0 && lastTransactionBlockNumber[_add]<add(27000000, origin_block)){
            
            dexamillions=0;
            millions=0;
            hundredks=0;
            tenks=0;
            ks=0;
            hundreds=0;
                
            stage = 0;
            loop = 0;
            
            lastBlockNumber = block.number;
            
            if (lastBlockNumber>add(origin_block, 27000000)){
                lastBlockNumber = add(origin_block, 27000000);
            }
            
            
            
            uint256 balance = temp_balances[_add];
             
            difference = sub(lastBlockNumber, lastTransactionBlockNumber[_add]);
           

            
            if (difference>10000000){
                
                loop = add(loop, 1);
                
                dexamillions = div(difference, 10000000);
                
                for (uint256 i=0; i<dexamillions; i++){
                    
                    stages[stage]=balance;
                
                    stage = add(stage, 1);
                    
                    balance = div(mul(balance, 3593813), 100000000000);
                }
                
                difference = sub(difference, mul(dexamillions, 10000000));
            }
            
            if (difference>1000000){
                
                loop = add(loop, 1);
                
                millions = div(difference, 1000000);
                
                for (i=0; i<millions; i++){
                    
                    stages[stage]=balance;
                
                    stage = add(stage, 1);
                    
                    balance = div(mul(balance, 35938136636), 100000000000);
                }
                
                difference = sub(difference, mul(millions, 1000000));
            }
            
            if (difference>100000){
                
                loop = add(loop, 1);
                
                hundredks = div(difference,100000);
                
                for (i=0; i<hundredks; i++){
                    
                    stages[stage]=balance;
                
                    stage = add(stage, 1);
                    
                    balance = div(mul(balance, 90272517794), 100000000000);
                    
                }
                
                difference = sub(difference, mul(hundredks, 100000));
                
                 
                
                 
                
                 
                
                
            }
            
            if (difference>10000){
                
                loop = add(loop, 1);
                
                tenks=div(difference, 10000);
                
                for (i=0; i<tenks; i++){
                    
                    stages[stage]=balance;
                
                    stage = add(stage, 1);
                    
                    balance = div(mul(balance, 98981847473), 100000000000);
                    
                }
                
                 
                
                difference = sub(difference, mul(tenks, 10000));
                
                 
                
                 
            }
            
            if (difference>1000){
                ks = div(difference, 1000);
                
                balance = div(mul(balance, sub(100000000000, mul(102284769, ks))), 100000000000);
                difference = sub(difference, mul(ks, 1000));
                
                stages[stage]=balance;
                
                stage = add(stage, 1);
                
            }
            
            if (difference>100){
                
                hundreds = div(difference, 100);

                balance = div(mul(balance, sub(100000000000, mul(10233188, hundreds))), 100000000000);
                difference = sub(difference, mul(hundreds,100));
                stages[stage]=balance;
                
                stage = add(stage, 1);
                
            }
            
            
            balance = div(mul(balance, sub(100000000000, mul(102337, difference))), 100000000000);
            
            stages[stage]=balance;

            totalSupply = add(sub(totalSupply, temp_balances[_add]), balance); 
            
            temp_balances[_add] = balance;

        }
        
        return true;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        
        burn(msg.sender);
        balanceOf[msg.sender] = temp_balances[msg.sender];
        
        require(balanceOf[msg.sender] >= _value);
        
        temp_balances[msg.sender] = sub(temp_balances[msg.sender], _value);

        balanceOf[msg.sender] = sub(balanceOf[msg.sender], _value);
        balanceOf[_to] = add(balanceOf[_to], _value);

        emit Transfer(msg.sender, _to, _value);
        
        burn(_to);
        temp_balances[_to] = add(temp_balances[_to], _value);
        
        lastTransactionBlockNumber[_to]=block.number;
        lastTransactionBlockNumber[msg.sender]=block.number;

        return true;
    }


}