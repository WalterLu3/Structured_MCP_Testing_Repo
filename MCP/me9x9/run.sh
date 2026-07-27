#!/bin/bash

gams data.gms s=save/data

gams chk.gms r=save/data s=save/

gams me9x9 r=save/chk