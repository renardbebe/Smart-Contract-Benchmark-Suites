 

pragma solidity ^0.4.10;

contract Fyer {
    string  public name = "Fyer";
    string  public symbol = "FYER";
    string  public standard = "DApp Token v1.0";
    uint256 public totalSupply;
    uint256 public decimals=18;

    uint256 public origin_block = 0;
    
    mapping(address => uint256) public balanceOf;
    mapping(address => uint256) public temp_balances;
    mapping(address => uint256) public lastBurnBlockNumber;
    
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => mapping(address => uint256)) public temp_allowance;
    mapping(address => mapping(address => uint256)) public lastAllowanceBurnBlockNumber; 
    
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

    constructor () public {
        totalSupply = 100000000000000*(10**(decimals));
        balanceOf[msg.sender] = totalSupply;
        temp_balances[msg.sender] = totalSupply;
        origin_block = block.number;
        lastBurnBlockNumber[msg.sender] = origin_block;

    }
    
    function burn (address _add) public returns(bool success){
        
        uint256 unit;
        uint256 lastBurnBlockNumber_add = lastBurnBlockNumber[_add];
        uint256 lastBlockNumber = block.number;
        uint256 difference = lastBlockNumber - lastBurnBlockNumber_add;
        
        
        if (lastBurnBlockNumber_add<(27000000 + origin_block)){
            
            if (lastBlockNumber>(origin_block+27000000)){
                lastBlockNumber = origin_block + 27000000;
            }
            
            
            uint256 balance = temp_balances[_add];
           
            
            if (difference>10000000){
                
                unit = (difference/10000000);
                
                for (uint256 i=0; i<unit; i++){
                    
                    balance = ((balance*3593813)/100000000000);
                }
                
                difference = (difference-(unit*10000000));
            }
            
            if (difference>1000000){
                
                unit = (difference/1000000);
                
                for (i=0; i<unit; i++){
                    
                    balance = ((balance*35938136636)/100000000000);
                }
                
                difference = (difference-(unit*1000000));
            }
            
            if (difference>100000){
                
                unit = (difference/100000);
                
                for (i=0; i<unit; i++){
                    
                    balance = ((balance*90272517794)/100000000000);
                    
                }
                
                difference = (difference-(unit*100000));

                
            }
            
            if (difference>10000){
                
                unit=(difference/10000);
                
                for (i=0; i<unit; i++){
                    
                    balance = ((balance*98981847473)/100000000000);
                    
                }
                
                difference = (difference-(unit*10000));

            }
            
            if (difference>1000){
                
                unit=(difference/1000);
                
                for (i=0; i<unit; i++){
                    
                    balance = ((balance*99897715231)/100000000000);
                    
                }
                
                difference = (difference-(unit*1000));

                
            }
            
            if (difference>100){
                
                unit = (difference/100);

                for (i=0; i<unit; i++){
                    
                    balance = ((balance*99989766812)/100000000000);
                    
                }
                
                difference = (difference-(unit*100));
            
            }
            
            if (difference>10){
                
                unit = (difference/10);

                for (i=0; i<unit; i++){
                    
                    balance = ((balance*99998976634)/100000000000);
                    
                }
                
                difference = (difference-(unit*10));
                
            }
            
            if (difference>1){
                
                unit = difference;

                for (i=0; i<unit; i++){
                    
                    balance = ((balance*99999897662)/100000000000);
                    
                }
                

            }

            totalSupply = ((totalSupply-temp_balances[_add])+balance); 
            
            temp_balances[_add] = balance;

        }
        
        lastBurnBlockNumber[_add]=lastBlockNumber;
        
        if (msg.sender==_add){
            balanceOf[msg.sender] = temp_balances[msg.sender];
        }
        
        return true;
    }
    
    function burn_allowance (address _add, address _add2) public returns (bool success){
        uint256 unit;
        uint256 lastBurnBlockNumber_add = lastAllowanceBurnBlockNumber[_add][_add2];
        uint256 lastBlockNumber = block.number;
        uint256 difference = lastBlockNumber - lastBurnBlockNumber_add;
        
        if (lastBurnBlockNumber_add<(27000000 + origin_block)){
            if (lastBlockNumber>(origin_block+27000000)){
                lastBlockNumber = origin_block + 27000000;
            }
            
            uint256 balance = temp_allowance[_add][_add2];
            
            if (difference>10000000){
                
                unit = (difference/10000000);
                
                for (uint256 i=0; i<unit; i++){
                    
                    balance = ((balance*3593813)/100000000000);
                }
                
                difference = (difference-(unit*10000000));
            }
            
            if (difference>1000000){
                
                unit = (difference/1000000);
                
                for (i=0; i<unit; i++){
                    
                    balance = ((balance*35938136636)/100000000000);
                }
                
                difference = (difference-(unit*1000000));
            }
            
            if (difference>100000){
                
                unit = (difference/100000);
                
                for (i=0; i<unit; i++){
                    
                    balance = ((balance*90272517794)/100000000000);
                    
                }
                
                difference = (difference-(unit*100000));

                
            }
            
            if (difference>10000){
                
                unit=(difference/10000);
                
                for (i=0; i<unit; i++){
                    
                    balance = ((balance*98981847473)/100000000000);
                    
                }
                
                difference = (difference-(unit*10000));

            }
            
            if (difference>1000){
                
                unit=(difference/1000);
                
                for (i=0; i<unit; i++){
                    
                    balance = ((balance*99897715231)/100000000000);
                    
                }
                
                difference = (difference-(unit*1000));

                
            }
            
            if (difference>100){
                
                unit = (difference/100);

                for (i=0; i<unit; i++){
                    
                    balance = ((balance*99989766812)/100000000000);
                    
                }
                
                difference = (difference-(unit*100));
            
            }
            
            if (difference>10){
                
                unit = (difference/10);

                for (i=0; i<unit; i++){
                    
                    balance = ((balance*99998976634)/100000000000);
                    
                }
                
                difference = (difference-(unit*10));
                
            }
            
            if (difference>1){
                
                unit = difference;

                for (i=0; i<unit; i++){
                    
                    balance = ((balance*99999897662)/100000000000);
                    
                }
                

            }
            
            temp_allowance[_add][_add2] = balance;
            
        }
        
        lastAllowanceBurnBlockNumber[_add][_add2] = lastBlockNumber;
        
        return true;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        
        burn(msg.sender);
        
        require(balanceOf[msg.sender] >= _value);
        
        temp_balances[msg.sender] = (temp_balances[msg.sender]-_value);
        balanceOf[msg.sender] = (balanceOf[msg.sender] - _value);
        
        burn(_to);
        balanceOf[_to] = balanceOf[_to] + _value;
        temp_balances[_to] = temp_balances[_to]+_value;
        
        emit Transfer(msg.sender, _to, _value);

        return true;
    }
    
    function transfer_percentage(address _to, uint256 _percentage) public returns (bool success) {
        
        burn(msg.sender);
        balanceOf[msg.sender] = temp_balances[msg.sender];
        
        require(_percentage<10000000000);
        
        uint256 _value = ((_percentage*balanceOf[msg.sender])/10000000000);
        
        require(balanceOf[msg.sender] >= _value);
        
        temp_balances[msg.sender] = (temp_balances[msg.sender] - _value);

        balanceOf[msg.sender] = (balanceOf[msg.sender]-_value);
        
        burn(_to);
        temp_balances[_to] = (temp_balances[_to]+ _value);
        balanceOf[_to] = (balanceOf[_to]+ _value);
        
        emit Transfer(msg.sender, _to, _value);
        
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        
        allowance[msg.sender][_spender] = _value;
        temp_allowance[msg.sender][_spender] = _value;
        lastAllowanceBurnBlockNumber[msg.sender][_spender]=block.number;
        
        emit Approval(msg.sender, _spender, _value);

        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
                
        require(_value <= balanceOf[_from]);
        require(_value <= allowance[_from][msg.sender]);
        
        burn(_from);
        
        burn_allowance(_from, msg.sender);
        
        require(_value <= temp_allowance[_from][msg.sender]);
        require(_value <= temp_balances[_from]);
        
        
        balanceOf[_from] = (balanceOf[_from] - _value);
        temp_balances[_from] = (temp_balances[_from] - _value);
        
        burn(_to);
        
        balanceOf[_to] = (balanceOf[_to] + _value);
        temp_balances[_to] = (temp_balances[_to] + _value);
        
        allowance[_from][msg.sender] = (allowance[_from][msg.sender] - _value);
        temp_allowance[_from][msg.sender] = (temp_allowance[_from][msg.sender] - _value);
        
        emit Transfer(_from, _to, _value);

        return true;
    }

}