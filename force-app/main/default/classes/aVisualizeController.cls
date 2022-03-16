// This controller is not used
global class aVisualizeController
{
    public aVisualizeController()
    {

    }
    
    @RemoteAction
    global static Boolean updateLifeforms ( )
    {
        List<LifeformElement> visualEcosystem = new List<LifeformElement>();
        List<LifeForm__c> ecosystem = new List<LifeForm__c>
        (
            [
                SELECT Index__c, Alive__c, X_Coordinate__c, Y_Coordinate__c, 
                        Neighbor_East__c, Neighbor_West__c, Neighbor_South__c, Neighbor_North__c,
                        Neighbor_NE__c, Neighbor_NW__c, Neighbor_SE__c, Neighbor_SW__c,
                        Neighbor_East__r.Alive__c, Neighbor_West__r.Alive__c, Neighbor_South__r.Alive__c, Neighbor_North__r.Alive__c,
                        Neighbor_NE__r.Alive__c, Neighbor_NW__r.Alive__c, Neighbor_SE__r.Alive__c, Neighbor_SW__r.Alive__c,
                        Neighbor_East__r.Index__c, Neighbor_West__r.Index__c, Neighbor_South__r.Index__c, Neighbor_North__r.Index__c,
                        Neighbor_NE__r.Index__c, Neighbor_NW__r.Index__c, Neighbor_SE__r.Index__c, Neighbor_SW__r.Index__c,
                        Neighbor_East__r.X_Coordinate__c, Neighbor_West__r.X_Coordinate__c, Neighbor_South__r.X_Coordinate__c, Neighbor_North__r.X_Coordinate__c,
                        Neighbor_NE__r.X_Coordinate__c, Neighbor_NW__r.X_Coordinate__c, Neighbor_SE__r.X_Coordinate__c, Neighbor_SW__r.X_Coordinate__c,
                        Neighbor_East__r.Y_Coordinate__c, Neighbor_West__r.Y_Coordinate__c, Neighbor_South__r.Y_Coordinate__c, Neighbor_North__r.Y_Coordinate__c,
                        Neighbor_NE__r.Y_Coordinate__c, Neighbor_NW__r.Y_Coordinate__c, Neighbor_SE__r.Y_Coordinate__c, Neighbor_SW__r.Y_Coordinate__c                        
                FROM LifeForm__c
                ORDER BY Index__c ASC
            ]        
        );
               
        for (LifeForm__c theCreature : ecosystem )
        {
            visualEcosystem.add(new LifeformElement(theCreature));
            //  if I am alive and I have other then 2-3 neighbors, I die
            // if I am dead and I have 3 neighbors then I come to life
            Integer myLiveNeighbors = countLiveNeighbors(theCreature);
            if (theCreature.Alive__c && myLiveNeighbors != 2 && myLiveNeighbors != 3) theCreature.Alive__c = false;
            else if (!theCreature.Alive__c && myLiveNeighbors == 3 ) theCreature.Alive__c = true;
        }
        try
        {
            update ecosystem;
        }
        catch (exception e)
        {
            return false;
        }
        return true;
    }
    
    public String GetLifeforms ( )
    {
        Map<Integer, LifeformElement> visualEcosystem = new Map<Integer, LifeformElement>();
        List<LifeForm__c> ecosystem = new List<LifeForm__c>
        (
            [
                SELECT Index__c, Alive__c, X_Coordinate__c, Y_Coordinate__c, 
                        Neighbor_East__c, Neighbor_West__c, Neighbor_South__c, Neighbor_North__c,
                        Neighbor_NE__c, Neighbor_NW__c, Neighbor_SE__c, Neighbor_SW__c,
                        Neighbor_East__r.Index__c, Neighbor_West__r.Index__c, Neighbor_South__r.Index__c, Neighbor_North__r.Index__c,
                        Neighbor_NE__r.Index__c, Neighbor_NW__r.Index__c, Neighbor_SE__r.Index__c, Neighbor_SW__r.Index__c,
                        Neighbor_East__r.Alive__c, Neighbor_West__r.Alive__c, Neighbor_South__r.Alive__c, Neighbor_North__r.Alive__c,
                        Neighbor_NE__r.Alive__c, Neighbor_NW__r.Alive__c, Neighbor_SE__r.Alive__c, Neighbor_SW__r.Alive__c,
                        Neighbor_East__r.X_Coordinate__c, Neighbor_West__r.X_Coordinate__c, Neighbor_South__r.X_Coordinate__c, Neighbor_North__r.X_Coordinate__c,
                        Neighbor_NE__r.X_Coordinate__c, Neighbor_NW__r.X_Coordinate__c, Neighbor_SE__r.X_Coordinate__c, Neighbor_SW__r.X_Coordinate__c,
                        Neighbor_East__r.Y_Coordinate__c, Neighbor_West__r.Y_Coordinate__c, Neighbor_South__r.Y_Coordinate__c, Neighbor_North__r.Y_Coordinate__c,
                        Neighbor_NE__r.Y_Coordinate__c, Neighbor_NW__r.Y_Coordinate__c, Neighbor_SE__r.Y_Coordinate__c, Neighbor_SW__r.Y_Coordinate__c                        
                FROM LifeForm__c
                ORDER BY Index__c ASC
            ]        
        );
        for (LifeForm__c theCreature : ecosystem )
        {
            visualEcosystem.put((Integer)theCreature.Index__c, new LifeformElement(theCreature));
        }
System.Debug('GetLifeforms' + visualEcosystem.get(0).NeighborIndx);        
        return json.serialize( visualEcosystem );
    }
    
    static Integer countLiveNeighbors( LifeForm__c life )
    {
        Integer theCount = 0;
        if (life.Neighbor_East__r.Alive__c) theCount++;
        if (life.Neighbor_West__r.Alive__c) theCount++;
        if (life.Neighbor_South__r.Alive__c) theCount++;
        if (life.Neighbor_North__r.Alive__c) theCount++;
        if (life.Neighbor_NE__r.Alive__c) theCount++;
        if (life.Neighbor_NW__r.Alive__c) theCount++;
        if (life.Neighbor_SE__r.Alive__c) theCount++;
        if (life.Neighbor_SW__r.Alive__c) theCount++;
        return theCount;
    }
    
    private class Position
    {
        Integer                    x;
        Integer                    y;
        
        public Position() {}
        public Position(LifeForm__c aLife) 
        { 
            if(aLife == null) return;
            x = Integer.valueOf(aLife.X_Coordinate__c); 
            y = Integer.valueOf(aLife.Y_Coordinate__c);
        }
    }
    
    public class LifeformElement
    {
        Position                    me;
        List<Position>              Neighbors;
        List<Integer>               NeighborIndx; 
        Boolean                     alive;
        Boolean                     nextState;
        //////////////////////
        //
        //  for the two arrays of neighbors -- one for positions and one for state
        //    they are created in the following order
        //
        //                  N (2)
        //          NW (3)  ^   NE (1)
        //                \ | /
        //        W (4) < -- --> E (0)
        //                / | \
        //          SW (5)      SE (7)
        //                  S (6)
        
        LifeformElement( LifeForm__c life)
        {
            Integer LiveCount = 0;
            me = new Position(life);
            alive = life.Alive__c;
            Neighbors = new List<Position>();
            NeighborIndx = new List<Integer>{null,null,null,null,null,null,null,null};
            Neighbors.add( new Position(life.Neighbor_East__r) );   // East is index 0
            if (life.Neighbor_East__r != null) 
            {
                if ( life.Neighbor_East__r.Alive__c ) LiveCount++;
                NeighborIndx[4] = (Integer)life.Neighbor_East__r.Index__c; // put in West position
            }
            else 
            {
                NeighborIndx[4] = null;
            }

            Neighbors.add( new Position(life.Neighbor_NE__r) );   // NE is index 1;
            if (life.Neighbor_NE__r != null) 
            {
                if ( life.Neighbor_NE__r.Alive__c ) LiveCount++;
                NeighborIndx[5] = (Integer)life.Neighbor_NE__r.Index__c;  // put in SW position
            }
            else 
            {
                NeighborIndx[5] = null;
            }
            
            Neighbors.add( new Position(life.Neighbor_North__r) );   // N is index 2
            if (life.Neighbor_North__r != null) 
            {
                if ( life.Neighbor_North__r.Alive__c ) LiveCount++;
                NeighborIndx[6] = (Integer)life.Neighbor_North__r.Index__c; // put in South position
            }
            else 
            {
                NeighborIndx[6] = null;
            }
            
            Neighbors.add( new Position(life.Neighbor_NW__r) );   // NW is index 3
            if (life.Neighbor_NW__r != null) 
            {
                if ( life.Neighbor_NW__r.Alive__c ) LiveCount++;
                NeighborIndx[7] = (Integer)life.Neighbor_NW__r.Index__c;  // put in SE position
            }
            else 
            {
                NeighborIndx[7] = null;
            }
            
            Neighbors.add( new Position(life.Neighbor_West__r) );   // W is index 4
            if (life.Neighbor_West__r != null) 
            {
                if ( life.Neighbor_West__r.Alive__c ) LiveCount++;
                NeighborIndx[0] = (Integer)life.Neighbor_West__r.Index__c;  // put in East position
            }
            else 
            {
                NeighborIndx[0] = null;
            }
                       
            Neighbors.add( new Position(life.Neighbor_SW__r) );   // SW is index 5
            if (life.Neighbor_SW__r != null) 
            {
                if ( life.Neighbor_SW__r.Alive__c ) LiveCount++;
                NeighborIndx[1] = (Integer)life.Neighbor_SW__r.Index__c;  // put in NE position
            }
            else 
            {
                NeighborIndx[1] = null;
            }
            
            Neighbors.add( new Position(life.Neighbor_South__r) );   // S is index 6
            if (life.Neighbor_South__r != null) 
            {
                if ( life.Neighbor_South__r.Alive__c ) LiveCount++;
                NeighborIndx[2] = (Integer)life.Neighbor_South__r.Index__c;  // put in North position
            }
            else 
            {
                NeighborIndx[2] = null;
            }
            
            Neighbors.add( new Position(life.Neighbor_SE__r) );   // SE is index 7
            if (life.Neighbor_SE__r != null) 
            {
                if ( life.Neighbor_SE__r.Alive__c ) LiveCount++;
                NeighborIndx[3] = (Integer)life.Neighbor_SE__r.Index__c;  // put in NW position
            }
            else 
            {
                NeighborIndx[3] = null;
            }
            nextState = alive;
            if(alive && LiveCount !=2 && LiveCount != 3) nextState = false;
            if(!alive && LiveCount == 3) nextState = true;
System.Debug(life.Index__c + ' NeighborIndx ' + LiveCount + ' ' + nextState + ' ' + alive);
System.Debug(NeighborIndx);
        }
    }
}