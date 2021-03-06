
/*******************************************************************************/
/* Copyright (C) 2008 Jonathan Moore Liles                                     */
/*                                                                             */
/* This program is free software; you can redistribute it and/or modify it     */
/* under the terms of the GNU General Public License as published by the       */
/* Free Software Foundation; either version 2 of the License, or (at your      */
/* option) any later version.                                                  */
/*                                                                             */
/* This program is distributed in the hope that it will be useful, but WITHOUT */
/* ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or       */
/* FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for   */
/* more details.                                                               */
/*                                                                             */
/* You should have received a copy of the GNU General Public License along     */
/* with This program; see the file COPYING.  If not,write to the Free Software */
/* Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.  */
/*******************************************************************************/

/* a Digital Peak Meter, either horizontal or vertical.  Color is a
   gradient from min_color() to max_color(). box() is used to draw the
   individual 'lights'. division() controls how many 'lights' there
   are. value() is volume in dBFS */

#include "DPM.H"

/* we cache the gradient for (probably excessive) speed */
float DPM::_dim;
Fl_Color DPM::_gradient[128] = { (Fl_Color)0 };
Fl_Color DPM::_dim_gradient[128];

#include <FL/Fl.H>
#include <FL/fl_draw.H>
#include <FL/Fl_Group.H>

#include <math.h>
#include <stdio.h>

DPM::DPM ( int X, int Y, int W, int H, const char *L ) :
    Meter( X, Y, W, H, L )
{
    tooltip( peak_string );

    _last_drawn_hi_segment = 0;

    pixels_per_segment( 4 );

    type( FL_VERTICAL );

//    resize( X, Y, W, H );

    dim( 0.85f );

    /* initialize gradients */
    if ( DPM::_gradient[ 0 ] == 0 )
    {
        int breaks[] = {0,60,70,80,90,127};

        Fl_Color cols[] = { 
            fl_rgb_color( 45,58,64),
            fl_rgb_color( 84,181,195 ), 
            fl_rgb_color( 122,200,211 ), 
            fl_rgb_color( 178,213,212 ), 
            fl_rgb_color( 209,213,179 ),
            fl_rgb_color( 250, 40, 30 )
        };

        DPM::blend( 6, breaks, cols );
    }

    box( FL_FLAT_BOX );
    color( FL_BACKGROUND_COLOR );

    resize( X,Y,W,H);
}

/* which marks to draw beside meter */
const int marks [] = { -70, -50, -40, -30, -20, -10, -3, 0, 4 };

void
DPM::draw_label ( void )
{

    /* dirty hack */
    if ( parent()->child( 0 ) == this )
    {
        fl_font( FL_TIMES, 8 );
        fl_color( FL_WHITE );
        /* draw marks */
        char pat[5];
        if ( type() == FL_HORIZONTAL )
        {
            for ( int i = sizeof( marks ) / sizeof( marks[0] ); i-- ; )
            {
                sprintf( pat, "%d", marks[ i ] );

                int v = w() *  deflection( (float)marks[ i ] );

                fl_draw( pat, x() + v, (y() + h() + 8), 19, 8, (Fl_Align) (FL_ALIGN_RIGHT | FL_ALIGN_TOP) );
            }

        }
        else
        {
            for ( int i = sizeof( marks ) / sizeof( marks[0] ); i-- ; )
            {
                sprintf( pat, "%d", marks[ i ] );

                int v = h() *  deflection( (float)marks[ i ] );

                fl_draw( pat, x() - 20, (y() + h() - 4) - v, 19, 8, (Fl_Align) (FL_ALIGN_RIGHT | FL_ALIGN_TOP) );
            }
        }
    }
}

void
DPM::resize ( int X, int Y, int W, int H )
{
    int old_segments = _segments;
  
    Fl_Widget::resize( X, Y, W, H );
    
    int tx,ty,tw,th;
    bbox(tx,ty,tw,th);

    if ( type() == FL_HORIZONTAL )
        _segments = floor( tw / (double)_pixels_per_segment );
    else
        _segments = floor( th / (double)_pixels_per_segment );
    
    if ( old_segments != _segments )
        _last_drawn_hi_segment = 0;
}

void DPM::bbox ( int &X, int &Y, int &W, int &H )
{
    X = x() + 2;
    Y = y() + 2;
    W = w() - 4;
    H = h() - 4;
}

void
DPM::draw ( void )
{
    snprintf( peak_string, sizeof( peak_string ), "%.1f", peak() );
    tooltip( peak_string );

    int X,Y,W,H;
    bbox(X,Y,W,H);

    int v = pos( value() );
    int pv = pos( peak() );
    
    int clipv = pos( 0 );

    int bh = H / _segments;
    /*  int bh = _pixels_per_segment; */
    /* int bw = _pixels_per_segment; */
    int bw = W / _segments;

    if ( damage() & FL_DAMAGE_ALL )
    {
        draw_label();

        draw_box( FL_FLAT_BOX, x(), y(), w(), h(), FL_DARK1 );
    }

    fl_push_clip( X, Y, W, H );

    const int active = active_r();

    int hi, lo;
 
    /* only draw as many segments as necessary */
    if ( damage() == FL_DAMAGE_USER1 )
    {
        if ( v > _last_drawn_hi_segment )
        {
            hi = v;
            lo = _last_drawn_hi_segment;
        }
        else
        {
            hi = _last_drawn_hi_segment;
            lo = v;
        }
    }
    else
    {
        lo = 0;
        hi = _segments;
    }

    _last_drawn_hi_segment = v;

    for ( int p = lo; p <= hi; p++ )
    {
        Fl_Color c;

        if ( p <= v )
        {
            if (  p == clipv )
                c = fl_color_average( FL_YELLOW, div_color( p ), 0.40 );
            else
                c = div_color( p );
        }
        else if ( p == pv )
            c = div_color( p );
        else
            c = dim_div_color( p );
        
        if ( ! active )
            c = fl_inactive( c );

        int yy = 0;
        int xx = 0;
             
        if ( type() == FL_HORIZONTAL )
        {
            xx = X + p * bw;
            fl_rectf( X + (p * bw), Y, bw, H, c );
        }
        else
        {
            yy = Y + H - ((p+1) * bh);
            fl_rectf( X, yy, W, bh, c );
        }
        
        if ( _pixels_per_segment >= 3 )
        {
            fl_color( FL_DARK1 );

            if ( type() == FL_HORIZONTAL )
            {
                fl_line( xx, Y, xx, Y + H - 1 );
            }
            else
            {
                fl_line( X, yy, X + W - 1, yy );
            }
        }

        /* } */
        /* else */
        /* { */
        /*     if ( type() == FL_HORIZONTAL ) */
        /*         fl_draw_box( box(), X + (p * bw), Y, bw, H, c ); */
        /*     else */
        /*         fl_draw_box( box(), X, Y + H - ((p + 1) * bh), W, bh, c ); */
        /* } */
    }

    fl_pop_clip();
}
